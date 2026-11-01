# Writing KryNet Home Assistant automations

A recipe book for adding, changing or removing an automation on this fleet — written so an
agent can do it end to end without re-deriving the workflow or rediscovering the traps.

**Read `docs/SMART-HOME-DEVICE-INVENTORY.md` first** for the power tree, the label contract
(§4) and the energy model (§6). This file is *how*; that file is *what and why*.

---

## 0. The two rules that decide everything

**1. Target LABELS, never entity lists.**

```yaml
actions:
  - action: homeassistant.turn_off
    target:
      label_id: night_off        # ✅
```
```yaml
actions:
  - action: switch.turn_off
    target:
      entity_id: [switch.a, switch.b, switch.c]   # ❌ goes stale silently
```

An entity list rots the moment a device is added, and nothing tells you. With a label, adding
a plug is a label change and every automation picks it up. It also makes omission **visible** —
a device with no label is in no automation, which you can check in one query.

🔴 **The inverse matters too: a label that no automation reads is equally misleading.**
`away_off` was retired on 2026-09-06 for exactly this reason once its two consumers were
deleted. If you delete the last automation using a label, delete the label.

**2. `protected` is the safety boundary, enforced by construction.**

`protected` = Fridge Mains, Office Mains, Hall Mains, and the three Rack Strip sockets carrying
Mac, Legion and Agni. Nothing that switches things off may target it. Because the schedules
target `night_off` / `late_night_off`, they *cannot* reach a server — that is a structural
guarantee, not a convention to remember.

⚠️ Never write an automation that switches a `protected` entity. Alert instead. Self-healing
Agni is impossible (HA dies with it), and fighting a human who deliberately cut the fridge is
worse than telling them.

---

## 1. The deploy workflow — every automation change, in order

`config/ha/automations.yaml` in the repo is **intent**. HA reads `/config/automations.yaml`
inside the container. Editing the repo changes nothing until you copy it in.

```bash
cd ~/Work/Repos/personal/home-server

# 1. Edit the repo file, then sanity-parse it (plain YAML, no !include here)
python3 -c "import yaml,sys; d=yaml.safe_load(open('config/ha/automations.yaml')); print(len(d),'automations')"

# 2. Copy into the container
scp -q config/ha/automations.yaml agni:/tmp/automations.yaml
ssh agni 'docker cp /tmp/automations.yaml homeassistant:/config/automations.yaml && rm -f /tmp/automations.yaml'

# 3. 🔴 Validate with HA itself, and CHECK THE EXIT CODE.
#    A clean run prints only "Testing configuration at /config" — no output is not proof.
ssh agni 'docker exec homeassistant python3 -m homeassistant --script check_config -c /config; echo "EXIT=$?"'

# 4. Reload — no restart needed for automations/scripts/scenes/templates
ssh agni 'docker exec homeassistant \
  python3 -c "import urllib.request,os;
u=urllib.request.Request(\"http://127.0.0.1:8123/api/services/automation/reload\", data=b\"{}\",
  headers={\"Authorization\":\"Bearer \"+os.environ[\"T\"],\"Content-Type\":\"application/json\"});
print(urllib.request.urlopen(u).status)"'
```

Simpler reload via the REST API from the laptop:

```bash
TOK=$(cat ~/.ha/token | tr -d '[:space:]')
curl -s -X POST -H "Authorization: Bearer $TOK" \
  http://192.168.0.200:8123/api/services/automation/reload -d '{}'
```

### When a RESTART is required instead of a reload

| Changed | Reload enough? |
|---|---|
| `automations.yaml`, `scripts.yaml`, `scenes.yaml` | ✅ `automation.reload` / `script.reload` / `scene.reload` |
| `template:` sensors in `configuration.yaml` | ✅ `homeassistant.reload_all` |
| **`emulated_hue:` entity list** | 🔴 **Full restart.** No reload service exists |
| `powercalc`, `recorder`, integrations | 🔴 Full restart |

⚠️ **After a restart, `emulated_hue` binds its port ~70–90 s LATE.** Checking
`http://192.168.0.200:8080/api/pi/lights` immediately after HA's own API returns 200 gives a
connection error that looks like a failure. Poll until it answers JSON.

---

## 2. Recipes

### 2a. Time schedule (the most common)

```yaml
- id: 'night_cut_night_off'
  alias: "Night: cut night_off loads at 23:45"
  triggers:
    - trigger: time
      at: '23:45:00'
  actions:
    - action: homeassistant.turn_off
      target:
        label_id: night_off
      continue_on_error: true
  mode: single
```

🔴 **If you cut things at night, write the restore in the same change.** Seven loads were cut at
23:30 and only two ever came back, so five latched off and needed a manual switch-on every
morning for weeks. Asymmetry is the single most common defect here.

### 2b. Power-threshold sensor → the right way to sense an appliance

Never trust an appliance's own integration if a plug meters it. Build a `binary_sensor` with
hysteresis, then trigger off that:

```yaml
template:
  - binary_sensor:
      - name: "TV Is On"
        unique_id: "tv_is_on"
        device_class: power
        delay_on:  {minutes: 1}     # must stay above for 1 min
        delay_off: {minutes: 2}     # must stay below for 2 min
        state: "{{ states('sensor.tv_plug_current_consumption') | float(0) > 60 }}"
```

**Why the delays are not optional:** without them a channel change or a power blip strobes
whatever follows the sensor. Pick the threshold from **two measurements** — idle and active —
and record both in an `attributes: basis:` string so the next person can re-derive it. The TV's
idle is 25.9 W and 60 W sits clearly between idle and viewing.

### 2b-ii. Restore only PART of a label — use a domain-scoped service

A label can hold mixed domains. `homeassistant.turn_on` against it hits everything; a
**domain-scoped** service against the same label only touches that domain:

```yaml
    # night_off holds 5 switches AND 3 lights. This restores only the switches.
    - action: switch.turn_on
      target:
        label_id: night_off
```

**Verified 2026-09-07:** with all eight members off, `switch.turn_on` on `night_off` brought the
five switches up and left `light.desk_backlight`, `light.monitor_backlight` and
`light.tv_backlight` **off**. That is the fix for "why do my backlights come on at 7 a.m." — the
morning restore used `homeassistant.turn_on`, which lit them.

🔴 **Prefer this over inventing a second label.** Two labels for one set of devices drift apart;
a domain filter cannot. Reach for a new label only when the split is not along domain lines.

⚠️ Lights should generally be **opt-in**, not restored on a clock. A light switched on by a
schedule has no natural "off" unless you also write one — which is how the asymmetry bug above
started. Use a scene or voice instead.

### 2c. State follows state (TV backlight pattern)

```yaml
  triggers:
    - {trigger: state, entity_id: binary_sensor.tv_is_on, to: 'on',  id: 'tv_on'}
    - {trigger: state, entity_id: binary_sensor.tv_is_on, to: 'off', id: 'tv_off'}
  actions:
    - choose:
        - conditions: [{condition: trigger, id: 'tv_on'}]
          sequence: [{action: light.turn_on,  target: {entity_id: light.tv_backlight},
                      data: {brightness_pct: 35, transition: 3}, continue_on_error: true}]
        - conditions: [{condition: trigger, id: 'tv_off'}]
          sequence: [{action: light.turn_off, target: {entity_id: light.tv_backlight},
                      data: {transition: 5}, continue_on_error: true}]
```

🔴 **A slaved light must be excluded from blanket restores.** This automation only reacts to a
*transition*, so if something else turns the backlight on while the TV is off, nothing turns it
back off. Both the 07:00 restore and `good_morning_all_on` therefore re-assert it explicitly:

```yaml
    - if: [{condition: state, entity_id: binary_sensor.tv_is_on, state: 'off'}]
      then: [{action: light.turn_off, target: {entity_id: light.tv_backlight}}]
```

### 2d. "Do it at a time unless busy, then do it when free"

The pattern for anything you must not interrupt. Two triggers, a state condition and a time
window:

```yaml
  triggers:
    - {trigger: time, at: '01:00:00'}                                   # the intent
    - {trigger: state, entity_id: binary_sensor.tv_is_on, to: 'off'}    # the catch-up
  conditions:
    - {condition: state, entity_id: binary_sensor.tv_is_on, state: 'off'}
    - {condition: time, after: '01:00:00', before: '07:00:00'}          # ⚠️ REQUIRED
```

⚠️ **The time-window condition is what makes this safe.** Without it, switching the TV off at
21:00 fires the catch-up trigger and cuts the mains mid-evening. And without the second
trigger, a TV still on at 01:00 means the mains simply never gets cut that night — the saving
the automation exists for silently doesn't happen.

### 2e. Manual whole-house action → a SCRIPT, not an automation

Anything a human triggers on demand belongs in `scripts.yaml`, because scripts can be spoken to
Alexa and pressed in the app. See `goodnight_all_off` / `good_morning_all_on`.

Expose to Alexa in `configuration.yaml`:

```yaml
emulated_hue:
  entities:
    script.goodnight_all_off:
      name: "Goodnight"        # ← this is what you SAY. Keep it short and distinct.
      hidden: false
```

Then in the Alexa app: **Devices → Discover**. The script appears as a switch.

🔴 **`emulated_hue` has NO AUTHENTICATION.** Anything on the LAN can drive whatever is listed.
Only expose lights, scenes and scripts whose blast radius is acceptable — never a mains plug,
never anything `protected`. A script that targets only the night labels is safe *because* the
label boundary holds.

### 2f. Alert, don't act

```yaml
  actions:
    - action: script.alert_household
      data:
        title: "🚨 Refrigerator power anomaly"
        message: "Fridge Mains under 1 W for 30 minutes while switched on."
        spoken: "Emergency. Refrigerator power has dropped to zero."
        critical: true
```

Always use `script.alert_household`, never a single notify target. `notify.*_announce`
entities go `unavailable`, and with `continue_on_error: true` on a lone call the fridge
emergency failed **silently**. That script raises a local persistent notification first (cannot
fail), then fans out only to Echoes that are actually available, then best-effort to phones.

---

## 3. Traps that have each cost real time

🔴 **`numeric_state` triggers on a CROSSING, not on "currently below".** A charger idling at
6.8 W with a `below: 12` trigger never fires, because the value never crossed 12 from above.
This is why the old "smart charger cutoff" appeared to work but left the charger on all day.
If you need "is below right now", use a `template` trigger or a `binary_sensor` + state trigger.

🔴 **A Tapo P110/P116M does NOT report 0 W when switched off** — it holds a residual value
(measured: 7.3 W and 0.11 A ninety minutes after switching off). Only the **cumulative energy
counter** is trustworthy; it freezes the instant the relay opens. Any "is it really drawing
power" check must use the counter or its `derivative`, never `current_consumption`.

🔴 **An UNREACHABLE Tapo plug reports `0.0 W` rather than going `unavailable`.** A dead plug and
an idle plug are otherwise identical, and a stale zero summed into a total produces a plausible
wrong answer. `binary_sensor.metered_plug_reading_stale` exists for this and is a **condition on
the fridge sentinel** — do not delete it.

🔴 **An automation's `entity_id` is minted from its FIRST alias and never tracks renames.**
Changing the alias from "at 23:30" to "at 23:45" leaves `automation.night_cut_..._at_23_30`
in place, silently lying. Rename the entity_id explicitly via
`config/entity_registry/update` with `new_entity_id`.

🔴 **Deleting an automation from YAML leaves an `unavailable` registry orphan.** It looks like a
broken automation in the UI and pollutes any dashboard that globs `automation.*`. Remove it with
`config/entity_registry/remove` — and guard on the state being `unavailable` first, so you can
never delete a live one by mistake.

🔴 **Dashboards are in STORAGE mode.** `config/ha/dashboards/*.yaml` is intent only; HA renders
from `.storage/lovelace.<name>`. Editing the YAML changes nothing. Use
`scripts/ha-helper.sh push-dashboard <name>` and `diff-dashboard <name>`. This let 47+18 dead
entity references survive an entire rename pass.

⚠️ **`/api/states` can contain control characters** in an attribute, which breaks
`json.load`. Use `json.loads(text, strict=False)`.

⚠️ **Renaming an entity does not change a template sensor's `entity_id`** — that comes from
`unique_id`. Change `unique_id` and you orphan the statistics history.

---

## 4. Verification — an automation is not done until this passes

1. **`check_config` exit code is 0.** Not "no output" — the exit code.
2. **The automation is `on` and its entity_id matches its alias.**
3. **Label membership is what you expect**, via the template API:
   ```
   {% for l in ["night_off","late_night_off","protected"] %}{{l}} ({{ label_entities(l)|count }}): {{ label_entities(l)|join(", ") }}
   {% endfor %}
   ```
4. **Trigger it for real and read the device states back.** For a schedule, call the underlying
   service or the equivalent script rather than waiting for the clock.
5. **No `unavailable` automation/script entities left behind.**
6. **Both dashboards `diff-dashboard` clean** if you touched any entity they reference.

🔴 **Back up `.storage` before any registry edit**, and stream it from *inside* the container —
`.storage/auth` is root-owned, so a host-side `tar` fails on that one file:

```bash
DEST=~/Downloads/ha-storage-$(date -u +%Y%m%dT%H%M%SZ).tgz
[ -e "$DEST" ] && { echo "REFUSING: exists"; exit 1; }
ssh agni 'docker exec homeassistant tar czf - -C /config .storage' > "$DEST"
tar tzf "$DEST" | wc -l          # verify by CONTENT, not by exit code
```

---

## 5. HA or Alexa? Decide by capability, then by failure mode

| Put it in | When |
|---|---|
| **Home Assistant** | Anything triggered by **power/energy** — Alexa cannot see watts. Anything touching `protected`. Anything needing labels or groups. **All schedules** |
| **Alexa** | **Voice.** "Alexa, goodnight" → the exposed script. Routines whose only trigger is you speaking |

🔴 **Schedules belong in HA, not Alexa.** Tapo plugs are driven **locally** by HA over KLAP, so a
23:45 cut still runs during a WAN outage. An Alexa routine goes phone → Amazon cloud → Tapo
cloud → plug and **silently does nothing** when the internet is down.

🔴 **Never schedule the same thing in both.** Two systems cutting power at 23:45 is how you get
an unexplainable late-night mystery with no single place to look. Alexa triggers HA; it does not
duplicate it.

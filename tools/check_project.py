import re, sys, os
from pathlib import Path

root = Path(".")
errors = []

# 1) كل مسارات ext_resource في ملفات tscn موجودة فعلاً
for tscn in root.rglob("*.tscn"):
    text = tscn.read_text(encoding="utf-8")
    for m in re.finditer(r'\[ext_resource type="[^"]+" path="([^"]+)"', text):
        p = m.group(1)
        if not (root / p.removeprefix("res://")).exists():
            errors.append(f"{tscn}: مسار مفقود {p}")
    # 2) عدّ load_steps
    m = re.search(r"load_steps=(\d+)", text)
    ext = len(re.findall(r"\[ext_resource ", text))
    sub = len(re.findall(r"\[sub_resource ", text))
    if m and int(m.group(1)) != ext + sub + 1:
        errors.append(f"{tscn}: load_steps={m.group(1)} لكن الفعلي {ext+sub+1}")

# 3) كل السكربتات مُشار إليها من مكان ما (سكربتات class_name تُسجَّل عالمياً فتُستثنى)
for gd in root.rglob("*.gd"):
    if re.search(r'^class_name ', gd.read_text(encoding="utf-8"), re.M):
        continue
    rel = "res://" + gd.as_posix()
    refs = sum(rel in t.read_text(encoding="utf-8") for t in root.rglob("*.tscn")) + sum(
        rel in g.read_text(encoding="utf-8") for g in root.rglob("*.gd"))
    if refs == 0:
        errors.append(f"{gd}: غير مُشار إليه في أي مشهد أو سكربت")

# 4) مسارات project.godot
pg = (root / "project.godot").read_text(encoding="utf-8")
for m in re.finditer(r'"res://([^"]+)"', pg):
    if not (root / m.group(1)).exists():
        errors.append(f"project.godot: مسار مفقود res://{m.group(1)}")

# 5) مسارات العقد في السكربتات مقابل العقد في المشاهد المرتبطة
node_checks = {
    "scripts/digging/digging.gd": ("scenes/player/Player.tscn", ["DigRay", "SwingTimer"]),
    "scripts/player/player.gd": ("scenes/player/Player.tscn", ["Inventory"]),
    "scripts/player/isometric_camera.gd": ("scenes/world/Main.tscn", ["Camera3D"]),
    "scripts/world/pod.gd": ("scenes/pod/Pod.tscn", ["WaterTank/Area3D"]),
    "scripts/ui/hud.gd": ("scenes/ui/HUD.tscn", ["Root/TopLeft/HealthBar", "Root/TopLeft/WaterBar", "Root/DepthLabel", "Root/WallInfo", "Root/Message", "Root/InventoryPanel/Grid"]),
    "scripts/world/main.gd": ("scenes/world/Main.tscn", ["Player", "HUD", "Player/Digging"]),
}
for gd, (scene, nodes) in node_checks.items():
    stext = (root / scene).read_text(encoding="utf-8")
    declared = re.findall(r'\[node name="([^"]+)"', stext)
    full = set()
    for line in stext.splitlines():
        m = re.match(r'\[node name="([^"]+)"(?: parent="([^"]+)")?', line)
        if m:
            name, parent = m.group(1), m.group(2)
            if parent is None:
                full.add(name)
            else:
                prefix = parent if parent != "." else ""
                full.add((prefix + "/" + name) if prefix else name)
    # عقد المشاهد المُستنسخة (instance=) تُحتسب متوفرة تحت اسم الجذر
    instanced = re.findall(r'\[node name="([^"]+)" parent="[^"]*" instance=ExtResource', stext)
    for n in nodes:
        if n in full:
            continue
        parts = n.split("/")
        if parts[0] in instanced and len(parts) > 1:
            sub_scene_name = parts[0].rstrip("0123456789") or parts[0]
            sub_map = {"Player": "scenes/player/Player.tscn"}
            if parts[0] in sub_map:
                ssub = (root / sub_map[parts[0]]).read_text(encoding="utf-8")
                sub_declared = re.findall(r'\[node name="([^"]+)"', ssub)
                if "/".join(parts[1:]) in sub_declared or parts[1] in sub_declared:
                    continue
        if n.split("/")[-1] not in declared:
            errors.append(f"{gd}: العقدة '{n}' غير موجودة في {scene}")

# 6) مسافات بادئة: GDScript يجب أن يستخدم tabs
for gd in root.rglob("*.gd"):
    for i, line in enumerate(gd.read_text(encoding="utf-8").splitlines(), 1):
        if line.startswith("    "):
            errors.append(f"{gd}:{i}: مسافة بادئة بمسافات بدل tabs")

if errors:
    print("مشاكل:")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("فحص الاتساق: لا مشاكل ✓")

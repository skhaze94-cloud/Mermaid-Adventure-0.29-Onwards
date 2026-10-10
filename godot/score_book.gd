extends RefCounted
## Authoritative award ledger; base awards are preserved, combo extras are separate.
const WINDOW := 3.0
var categories: Dictionary = {}
var seen: Dictionary = {}
var combo_hits := 0
var combo_left := 0.0
var multiplier := 1
var damage_taken := 0
var finished := false
var result: Dictionary = {}
func tick(dt: float) -> void:
    combo_left = maxf(0.0,combo_left-dt)
    if combo_left == 0:
        combo_hits = 0
        multiplier = 1
func award(id: String, category: String, base: int, chain: bool) -> Dictionary:
    if seen.has(id) or finished: return {}
    seen[id] = true
    var extra := 0
    if chain:
        combo_hits += 1
        combo_left = WINDOW
        multiplier = 5 if combo_hits >= 10 else (3 if combo_hits >= 6 else (2 if combo_hits >= 3 else 1))
        extra = base*(multiplier-1)
    categories[category] = int(categories.get(category,0))+base
    categories["Combo"] = int(categories.get("Combo",0))+extra
    return {"points":base+extra,"base":base,"extra":extra,"category":category,"multiplier":multiplier}
func checkpoint() -> Dictionary:
    return {"categories":categories.duplicate(true),"seen":seen.duplicate(true)}
func rollback(saved: Dictionary) -> void:
    categories = saved.get("categories",{}).duplicate(true)
    seen = saved.get("seen",{}).duplicate(true)
    combo_left = 0.0
    combo_hits = 0
    multiplier = 1
    finished = false
    result.clear()
func complete(total: int, pearls: int, previous_best: int) -> Dictionary:
    if finished: return result
    var bonus := 0
    if damage_taken == 0: bonus += 250
    if pearls >= 20: bonus += 100
    categories["Stage bonuses"] = bonus
    var accounted := 0
    for value in categories.values(): accounted += int(value)
    if accounted != total+bonus: categories["Other"] = total+bonus-accounted
    total += bonus
    finished = true
    result = {"total":total,"breakdown":categories.duplicate(true),"stars":3 if total >= 6000 else (2 if total >= 3000 else 1),"best":maxi(total,previous_best),"new_record":total>previous_best,"perfect":damage_taken==0,"pearl_bonus":pearls>=20,"reward":"Mermaid Bubble unlocked","rules":"1 star: stage clear · 2: 3,000 points · 3: 6,000 points"}
    return result


extends RefCounted
## Core jokes and lessons adapted from the supplied HTML Tutorial 2.0.
const NODES := {
"intro":["king","Lord of Thunder & Bedtime","Sarah! The hour has come!\nSarah: For what?\nKing Daddy: Training. Extremely elite training.",[
    ["I’m ready, Dad!","earnest","That’s my brave little mermaid. Three glowing rings first. No hurry, no pressure."],
    ["Is the rock on the teaching staff?","cheeky","An elite rock. It has requested a parking space. Your mother declined."],
    ["Can you show me how?","curious","Of course. Your tail steers in every direction. Try a gentle dive, then swim up again."]]],
"reef":["king","Behold. The rock.","Sarah: It’s a rock.\nKing Daddy: An elite rock. Swim through the open reef passage. The three relic chests are optional treasures.",[
    ["I’ll take the safe route.","earnest","Excellent. Look ahead, steer around stone, and let your tail do the work."],
    ["Does it have a health bar?","cheeky","Not yet. It is still negotiating its contract."],
    ["Where did the treasure come from?","curious","Mum hid three chests at different depths. Curiosity deserves a reward."]]],
"boost":["king","Very dignified zoomies","Aim first, little pearl. Then—zoom!\nKing Daddy: Use Boost when your aqua bar is nearly half full. It refills while you swim.",[
    ["Stand back. Zoomies incoming.","cheeky","The royal beard has been secured. Proceed."],
    ["I’ll aim before I boost.","earnest","Beautiful. A little control makes a big difference."],
    ["What if the bar runs out?","curious","Keep swimming while it recharges. We have all the time in the lagoon."]]],
"jump":["king","Time to meet the sky","Let’s say hello to the sky.\nKing Daddy: Start underwater, then Jump. Steer through the air and splash back into the sea.",[
    ["One small splash first.","earnest","A wonderful start. Land gently; you can practise as often as you like."],
    ["Please rate my landing kindly.","cheeky","I have already ordered the trophy. Your mother is checking the invoice."],
    ["Can I bounce again?","curious","Tap Jump around splashdown to chain a second leap. Watch your landing."]]],
"air":["king","Over the reef!","Start to the left of the tall reef, jump, then steer right. Land beyond it.\nSarah: Please tell the reef to stay still.",[
    ["Aim, jump, steer, land.","earnest","Exactly. Four little steps, one magnificent splash."],
    ["Ten out of ten, please.","cheeky","Eleven. The extra point is for confidence."],
    ["What if I bump it?","curious","You are safe here. Swim back to the left, refill your energy, and try again."]]],
"gifts":["queen","The Department of Common Sense","There you are, darling! I brought a pink heart and a gold boost gift.\nSarah: Are you here for mermaid school?\nAntonella: Quality control. His lesson plan said ‘THUNDER???’.",[
    ["What do the gifts do?","curious","The heart restores health. Gold gives eight seconds of unlimited boost. Collect both, jump, and land to finish."],
    ["Watch my big jump, Mum!","earnest","Every glorious splash, darling. I’ll refill the gold if you need another try."],
    ["Three question marks? Really, Dad?","cheeky","Antonella: And no learning outcomes.\nDaddy: The rock had a label.\nAntonella: That is not a curriculum."]]],
"practice":["queen","Three highly trained volunteers","Meet Professor Puff, Sir Wobble and Noodle. Use a Boost boop to clear each one.\nDaddy: They signed the waiver.\nAntonella: They signed a lunch menu.",[
    ["Gentle boops only.","earnest","That’s the spirit. Our volunteers are here to help you learn."],
    ["Is Noodle actually pasta?","cheeky","A career change is being considered. Please respect his privacy."],
    ["How do I aim my boop?","curious","Swim toward a volunteer, aim at it, then Boost. You cannot lose your last three hearts here."]]],
"trial":["king","The ancient trials!","Dodge my slow spells. When my shield opens with mint petals, Boost into me. Three good hits!\nAntonella: None of his moves are patented.",[
    ["I’m ready for the green glow.","earnest","Aim, boost, and believe in your tail. I am very proud of you."],
    ["Your cloud looks friendly.","cheeky","FEAR THE CLOUD!\nSarah: It likes me.\nDaddy: That is a professional boundary issue."],
    ["Can you explain your moves?","curious","Watch the aim line, slow bolts, friendly cloud, wobble wave, Dad Dash and Bubble Beard Blast. After that: mint petals mean GO!"]]],
"win":["king","Feared across three bathtubs","That’s my brilliant little mermaid!\nSarah: I survived the Bubble Beard Blast.\nAntonella: Two bathtubs. One was the sink.\nDaddy: The records are disputed.",[
    ["One last hug?","earnest","Always, little mermaid. You have earned every splash."],
    ["Can I have the lightning staff?","cheeky","No. Your mother would issue a very strongly worded look."],
    ["What is that tiny giggle?","curious","Antonella: Avina has discovered hide-and-seek. Check the coral just before the portal!"]]],
"bubble":["queen","A little bubble magic","Avina has a tiny bubble for you, darling.\nAntonella: Tap Bubble for a little pearl. Or hold until Royal Aurora is ready, then release.",[
    ["How do I aim it?","curious","Face the pearl target at the same depth. Hold Bubble for 1.35 seconds, then release. The big bubble flies straight ahead."],
    ["Can Avina help too?","earnest","She has her own tiny bubbles, darling. This practice target needs Sarah’s big Royal Aurora. You can also leave it and take the portal."],
    ["A very dignified bubble beard?","cheeky","Daddy: Mine took years of practice.\nAntonella: And one extremely patient bath towel."]]],
"hide":["queen","A very tiny surprise","A giggle behind the coral! Avina wants three rounds of peekaboo before you go.\nDaddy: Her hiding technique is mostly bow.",[
    ["I’ll find you, little pearl!","earnest","Swim close to the sparkling plants. Look for her little bow. She will pop out when you reach her."],
    ["The bow is giving you away!","cheeky","Avina: Hee!\nAntonella: Please do not tell the bow. It is doing its best."],
    ["Is she safe behind the coral?","curious","Completely. We’re right here. Follow the tiny bubbles; there is no timer or penalty."]]]}

static func farewell(along: bool, king_tone: String, queen_tone: String) -> Array:
    var king := "Your bubble squad has my royal blessing. Protect each other, little adventurers!" if along else "A solo explorer! I’ll stay with Avina. The thunder lessons will be strictly nursery-sized."
    var queen := "She only makes little bubbles, darling. Stay together. We are both cheering you on." if along else "Avina will stay with us. Go enjoy your adventure, darling. We’ll save you a very tiny cuddle."
    if king_tone=="cheeky": king += " The beard is available for emergency hugs. No appointment necessary."
    elif king_tone=="curious": king += " Remember: look ahead, aim before you boost, and wait for green."
    if queen_tone=="cheeky": queen += " And please leave the lightning staff here. I have counted it."
    elif queen_tone=="curious": queen += " You can always revisit this lagoon from Choose a chapter."
    return [king,queen]


## One speaker per beat. Explicit names change the portrait as well as the text.
static func beats(text: String, first_speaker: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var speaker := first_speaker
    for raw in text.split("\n",false):
        var line := String(raw).strip_edges()
        for prefix in {"King Daddy:":"king","Daddy:":"king","Antonella:":"queen","Sarah:":"sarah","Avina:":"avina"}:
            if line.begins_with(prefix):
                speaker={"King Daddy:":"king","Daddy:":"king","Antonella:":"queen","Sarah:":"sarah","Avina:":"avina"}[prefix]
                line=line.trim_prefix(prefix).strip_edges()
                break
        if not line.is_empty():result.append({"speaker":speaker,"text":line})
    return result

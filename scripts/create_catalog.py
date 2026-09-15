import json
from pathlib import Path
# Original teaching material; dictionary links verify the taught sense, not these examples.
rows = [
('work','bring up','Introduce a topic into a conversation.','話題を切り出す。','The meeting is almost over, but nobody has discussed the deadline. What do you say?',"Before we finish, can I bring up the deadline?",'Your friend keeps cancelling. Raise it without sounding accusatory.',"There's something I'd like to bring up. Is this still a good time for us to meet?",'Can I bring something up?','Separable: bring it up, not bring up it. A soft opener helps with sensitive topics.','Bring up starts a topic; bring about causes a change.'),
('work','get across','Communicate an idea so someone understands it.','考えや意図を相手に伝える。','A colleague thinks you want to cancel the project. You only want more time. Clarify.',"What I'm trying to get across is that we need more time, not a different project.",'A friend misunderstood your concern as criticism. Clarify your intention.',"I didn't get my point across very well. I just want you to have some support.",'What I’m trying to get across is…','Separable: get the point across / get it across. Often about whether a message was understood.','Get across is about communicating; come across is about the impression you give.'),
('work','follow up','Take further action after an earlier conversation.','前の話や依頼について、その後の確認をする。','You sent a proposal last week and have heard nothing. Ask for an update.',"I wanted to follow up on the proposal. Have you had a chance to look at it?",'A friend mentioned a useful contact. Ask about the introduction.',"Can I follow up on that introduction you mentioned?",'Follow up on something / with someone','Keep the object after on: follow up on it. The verb has no hyphen; a follow-up email does.','Follow up continues an earlier contact; catch up exchanges missed news.'),
('work','push back','Express resistance to a suggestion or demand.','提案や要求に異議を唱える。','Someone proposes a deadline your team cannot meet. Disagree constructively.',"Can I push back on that timeline? We'd have to cut the testing short.",'A friend wants everyone to split an expensive bill equally. Object politely.',"I'd like to push back on splitting it equally. Some people ordered much less.",'Push back on a proposal','Use on before the proposal. This sense is conversational and can sound firm; give a reason.','Push back on a date objects to it; push the date back postpones it.'),
('work','talk through','Discuss something carefully, step by step.','順を追って話しながら検討する。','A new teammate is confused about your plan. Offer to explain it together.',"Let's talk through the plan before we start.",'Your partner is worried about moving. Suggest discussing the options.',"Could we talk through the options tonight?",'Talk something through / talk it through','Separable: talk it through. Talk someone through something focuses on guiding that person.','Talk through examines details; talk someone into something persuades them.'),
('work','wrap up','Finish an activity or discussion.','話し合いや作業を締めくくる。','The meeting has two minutes left. Ask for final comments.',"Let's wrap up. Is there anything we haven't covered?",'You are on a long call and need to leave. End it warmly.',"I should wrap up, but it was lovely talking to you.",'Let’s wrap up / wrap something up','Can stand alone or take an object: wrap the meeting up. Warm in speech; conclude is more formal.','Wrap up finishes; wind down gradually reduces activity.'),
('connect','catch up','Exchange news after time apart.','久しぶりに近況を話し合う。','You run into an old friend and want a proper conversation later.',"We should catch up properly. Are you free for coffee this week?",'A colleague has returned from a long trip. Suggest lunch.',"Let's catch up over lunch. I'd love to hear how the trip went.",'Catch up with someone / over coffee','With introduces the person. No direct object in this sense: catch up with her.','Catch up with a friend exchanges news; catch up on work deals with a backlog.'),
('connect','open up','Begin sharing personal thoughts or feelings.','心を開いて気持ちを話す。','A friend finally tells you why they have been distant. Respond kindly.',"Thanks for opening up to me. That sounds like a lot to deal with.",'Explain why you do not talk much about personal things at work.',"It takes me a while to open up to people I don't know well.",'Open up to someone / about something','Intransitive in this sense. Let people choose what to share; do not pressure them.','Open up is becoming more willing to share; speak up is making yourself heard.'),
('connect','reach out','Contact someone, often for help or connection.','連絡を取る。支援を求める・申し出る文脈でも使う。','A friend is going through a difficult week. Offer support.',"Please reach out if you want to talk. You don't have to handle this alone.",'You want advice from someone you have not spoken to in months.',"I thought I'd reach out because you know this field much better than I do.",'Reach out to someone','Keep to before the person. Common in supportive and professional speech; contact is more neutral.','Reach out starts contact; follow up returns to an earlier exchange.'),
('connect','drift apart','Gradually become less close.','少しずつ疎遠になる。','Someone asks why you rarely see an old friend. Explain without blame.',"We didn't fall out. We just drifted apart after moving to different cities.",'Describe how a busy period affected a friendship.',"I think we drifted apart because we stopped making time for each other.",'We drifted apart','Intransitive. Usually suggests gradual change rather than a specific argument.','Drift apart is gradual; fall out means have a disagreement that damages the relationship.'),
('connect','let down','Disappoint someone who was relying on you.','期待や信頼に応えられず、がっかりさせる。','You forgot to help a friend move. Apologize without making excuses.',"I'm sorry I let you down. You were counting on me to be there.",'Explain why you hesitate to accept another commitment.',"I don't want to say yes and then let everyone down.",'Let someone down / let them down','Separable: let her down. More personal than simply disappoint when trust is involved.','Let down disappoints; turn down declines an offer or request.'),
('connect','bring out','Make a quality in someone more noticeable.','人の持つ性質を引き出す。','Explain why you enjoy spending time with a particular friend.',"She brings out my playful side. I don't take everything so seriously around her.",'Tell a mentor how their support affects the team.',"You bring out the best in people by giving them room to try.",'Bring out the best in someone','Separable with an ordinary object: bring it out. Learn the whole chunk bring out the best in.','Bring out reveals a quality; bring up introduces a topic.'),
('plans','put off','Delay something until later.','予定や行動を先延ばしにする。','You have delayed booking an appointment for weeks. Admit it.',"I've been putting it off, but I'll book it today.",'The team is avoiding a difficult decision. Encourage action.',"We can't keep putting off the decision. Let's decide by Friday.",'Put something off / put off doing something','Separable: put it off. A following verb takes -ing: put off deciding.','Put off delays; call off cancels. Put someone off can also mean discourage them.'),
('plans','work out','Develop successfully or find a satisfactory resolution.','物事がうまくいく・良い結果になる。','A friend is worried about a new job. Reassure them without making promises.',"I hope it works out. It sounds like a good fit, and you can reassess later.",'Your original travel plan failed, but the alternative was good. Explain.',"The first plan fell through, but it all worked out in the end.",'I hope it works out','Intransitive for outcomes. Work something out can instead mean solve or calculate.','Work out is a successful outcome here; figure out focuses on understanding or solving.'),
('plans','fall through','Fail to happen as planned.','計画が実現せず、立ち消えになる。','Your accommodation was cancelled at the last minute. Explain the change.',"Our booking fell through, so we're looking for somewhere else to stay.",'A friend asks about a collaboration that never started.',"It fell through when the funding was withdrawn.",'The plan fell through','Intransitive: the deal fell through. The plan is the subject, not the person cancelling it.','Fall through describes failure of a plan; call off is an intentional cancellation.'),
('plans','turn down','Decline an offer, invitation, or request.','誘い・提案・依頼を断る。','You cannot take on a new project. Explain to a colleague.',"I had to turn it down. I wouldn't be able to give it enough attention.",'A friend offered you a spare concert ticket, but you cannot go.',"Thanks for thinking of me. I hate to turn down the offer, but I'm away that night.",'Turn something down / turn it down','Separable: turn it down, not turn down it. Giving a short reason softens a refusal.','Turn down declines; let down disappoints a person. Turn down also has a volume sense.'),
('plans','come up','Arise unexpectedly and need attention.','急な用事や問題が生じる。','You need to reschedule a call because of an unexpected issue.',"Something's come up. Could we move our call to tomorrow?",'Explain why you left dinner early without sharing private details.',"Something came up at home, so I had to leave early.",'Something has come up','Intransitive. A useful discreet explanation, but suggest a next step when cancelling.','Come up arises; bring up deliberately introduces a topic.'),
('plans','rule out','Exclude a possibility from consideration.','可能性や選択肢を除外する。','A friend asks if you would move abroad. Keep the possibility open.',"I wouldn't rule it out, but I'd need a good reason to move.",'An expensive option might still be worthwhile. Avoid dismissing it too soon.',"Let's not rule it out until we've seen the full cost.",'Rule something out / rule it out','Separable. Wouldn’t rule it out is deliberately less committed than I’m planning to.','Rule out excludes; put off postpones without necessarily rejecting.'),
('perspective','come across','Give a particular impression.','相手にある印象を与える。','You worry that a brief message sounded rude. Explain your intention.',"I didn't mean to come across as dismissive. I was just in a rush.",'Describe someone who seemed confident in an interview.',"She came across as thoughtful and comfortable with uncertainty.",'Come across as + adjective / noun','Keep as before the impression: come across as confident. This sense has no direct object.','Come across as concerns impression; get something across concerns communicating meaning.'),
('perspective','figure out','Understand or solve something by thinking.','考えて理解する・解決策を見つける。','You do not yet understand why a plan failed. Explain what you need to do.',"I'm still trying to figure out what went wrong.",'You are choosing between two places to live. Ask for time.',"I need a few days to figure out which option makes more sense.",'Figure something out / figure out why…','Separable: figure it out. Often implies effort rather than simply receiving an explanation.','Figure out is understanding or solving; find out is discovering information.'),
('perspective','back up','Support a claim with evidence.','根拠を示して主張を裏付ける。','A colleague makes a strong prediction. Ask for evidence without attacking them.',"Do we have any data to back that up?",'Someone doubts your explanation. Offer supporting examples.',"I can back it up with a couple of examples from last month.",'Back something up / back it up','Separable. Evidence backs up a claim; a person can also back someone up by supporting them.','Back up supports a claim; bring up introduces it.'),
('perspective','go over','Review or examine something carefully.','内容を確認し直す・詳しく検討する。','You want to make sure everyone understands the agreement.',"Can we go over what we've agreed before we leave?",'Your friend wants help preparing for an interview. Offer practice.',"Let's go over the questions you're most worried about.",'Go over something / go over it','Inseparable in this sense: go over it, not go it over. Often a review of existing material.','Go over reviews details; get over can mean recover from something.'),
('perspective','think through','Consider the likely consequences carefully.','結果や影響までよく考える。','You like an idea but think a decision is premature.',"It could work, but we should think through the consequences first.",'A friend wants to quit immediately. Suggest reflection without telling them what to do.',"Have you had time to think it through? You might want a plan for what comes next.",'Think something through / think it through','Separable. Usually emphasizes a complete chain of consequences, not just initial consideration.','Think through follows implications; think over weighs a proposal before deciding.'),
('perspective','point out','Draw attention to a fact or detail.','事実や見落とされている点を指摘する。','The group has missed a practical problem. Draw attention to it politely.',"Can I point out one thing? We haven't included travel time.",'A friend thanks you for noticing an error. Keep it friendly.',"I'm glad you found it helpful. I just wanted to point it out before you sent it.",'Point something out / point out that…','Separable: point it out. Tone matters; a soft opener makes correction less abrupt.','Point out highlights a fact; call out often implies public criticism.')
]
from catalog_expansion import rows as expansion
rows += expansion
source_entries = {"follow up": "follow-up_1", "look for": "look_1", "look back on": "look-back", "get along with": "get-along", "run out of": "run-out_1", "go ahead": "go-ahead_2"}
from easy_english import meanings as easy_meanings
assert set(easy_meanings) == {row[1] for row in rows}
phrases=[]
for i,r in enumerate(rows):
    scene,phrase,meaning,jp,cue,reply,tc,tr,frame,nuance,contrast=r
    phrases.append(dict(id=f'{i+1:02d}-'+phrase.replace(' ','-'),phrase=phrase,meaning=meaning,easyEnglish=easy_meanings[phrase],japanese=jp,scene=scene,cue=cue,reply=reply,transferCue=tc,transferReply=tr,frame=frame,nuance=nuance,contrast=contrast,source='https://www.oxfordlearnersdictionaries.com/definition/'+('american_english/get-along-with' if phrase == 'get along with' else 'english/'+source_entries.get(phrase, phrase.replace(' ','-')))))
from import_collection import merge_collection
phrases = merge_collection(phrases)
editorial = json.loads(Path(__file__).resolve().parent.joinpath('data/editorial-phrases.json').read_text())
known_names = {p['phrase'] for p in phrases} | {alias for p in phrases for alias in p.get('aliases', [])}
known_ids = {p['id'] for p in phrases}
for entry in editorial:
    names = {entry['phrase'], *entry.get('aliases', [])}
    if entry['id'] in known_ids or names & known_names:
        raise ValueError(f"Duplicate editorial lesson: {entry['id']}")
    if not entry['id'].startswith('editorial-'):
        raise ValueError(f"Editorial lesson requires a stable editorial ID: {entry['id']}")
    known_ids.add(entry['id'])
    known_names.update(names)
phrases.extend(editorial)
idioms = json.loads(Path(__file__).resolve().parent.joinpath('data/idioms.json').read_text())
for entry in idioms:
    names = {entry['phrase'], *entry.get('aliases', [])}
    if entry['id'] in known_ids or names & known_names:
        raise ValueError(f"Duplicate idiom lesson: {entry['id']}")
    if entry.get('kind') != 'idiom' or entry['id'] != 'idiom-' + entry['phrase'].replace(' ', '-'):
        raise ValueError(f"Idiom requires a stable ID and kind: {entry['id']}")
    known_ids.add(entry['id'])
    known_names.update(names)
phrases.extend(idioms)
levels = json.loads(Path(__file__).resolve().parent.joinpath('data/phrase-difficulty.json').read_text())
if set(levels) != {p['id'] for p in phrases} or not set(levels.values()) <= {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'}:
    raise ValueError('Review difficulty assignments for all catalog IDs before generating')
for phrase in phrases:
    if 'difficulty' in phrase and phrase['difficulty'] != levels[phrase['id']]:
        raise ValueError(f"Conflicting editorial difficulty: {phrase['id']}")
    phrase['difficulty'] = levels[phrase['id']]
# Keep the learning order stable when either authored collection grows.
order = json.loads(Path(__file__).resolve().parent.joinpath('data/catalog-order.json').read_text())
by_id = {phrase['id']: phrase for phrase in phrases}
if len(order) != len(by_id) or set(order) != set(by_id):
    raise ValueError('Catalog order must contain every lesson ID exactly once')
phrases = [by_id[lesson_id] for lesson_id in order]
translations = json.loads(Path(__file__).resolve().parent.joinpath('data/example-translations.json').read_text())
all_examples = {text for p in phrases for text in [p['reply'], p['transferReply'], p.get('referenceUsage', {}).get('example', '')] if text}
if set(translations) != all_examples or not all(isinstance(value, str) and value.strip() for value in translations.values()):
    missing = sorted(all_examples - set(translations))[:5]
    raise ValueError(f'Every example needs one authored Japanese meaning keyed by its exact English text; missing {missing}')
for phrase in phrases:
    examples = [phrase['reply'], phrase['transferReply'], phrase.get('referenceUsage', {}).get('example', '')]
    meanings = {text: translations[text] for text in examples if text in translations}
    if meanings:
        phrase['exampleTranslations'] = meanings
glosses = json.loads(Path(__file__).resolve().parent.joinpath('data/glosses.json').read_text())
missing = [phrase['id'] for phrase in phrases if phrase['id'] not in glosses]
if missing or set(glosses) - {phrase['id'] for phrase in phrases}:
    raise ValueError(f'Every catalog ID needs exactly one gloss; missing {missing[:5]} extra {sorted(set(glosses) - {p["id"] for p in phrases})[:5]}')
for phrase in phrases:
    gloss = glosses[phrase['id']].strip()
    if not gloss or len(gloss.split()) > 3 or gloss.endswith('.') or gloss.lower() == phrase['phrase'].lower():
        raise ValueError(f"Gloss must be one to three words and not the phrase itself: {phrase['id']} -> {gloss!r}")
    phrase['gloss'] = gloss
# Japanese for each usage tip and look-alike comparison, keyed by ID; the English pattern (frame) is not translated.
usage_ja = json.loads(Path(__file__).resolve().parent.joinpath('data/usage-notes-ja.json').read_text())
noted = {p['id'] for p in phrases if p['nuance'] or p['contrast']}
if set(usage_ja) != noted:
    raise ValueError(f'Japanese usage notes must cover exactly the IDs with a tip or comparison; missing {sorted(noted - set(usage_ja))[:5]} extra {sorted(set(usage_ja) - noted)[:5]}')
for phrase in phrases:
    notes = usage_ja.get(phrase['id'], {})
    if set(notes) - {'nuance', 'contrast'}:
        raise ValueError(f"Unknown usage note keys: {phrase['id']}")
    for key in ('nuance', 'contrast'):
        japanese = notes.get(key, '').strip()
        if bool(phrase[key]) != bool(japanese):
            raise ValueError(f"Japanese {key} must exist exactly when the English one does: {phrase['id']}")
        if japanese:
            phrase[key + 'Japanese'] = japanese
Path(__file__).resolve().parents[1].joinpath('Vow/Resources/phrases.json').write_text(json.dumps(phrases,ensure_ascii=False,indent=2)+'\n')
print(f'Wrote {len(phrases)} phrases including the supplied collection')

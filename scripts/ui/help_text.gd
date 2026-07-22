class_name HelpText
extends RefCounted

# 게임 규칙 안내문. 타이틀 화면을 없애면서 ESC 메뉴의 [도움말]로 옮겼다.

const BBCODE := "[center][font_size=34][color=eac77a]📖 게임 방법[/color][/font_size][/center]

[font_size=21][color=eac77a]🎯 목표[/color][/font_size]
버그베어(보스)의 HP를 0으로 만들면 승리. 내 HP가 0이 되면 패배.

[font_size=21][color=eac77a]🃏 타임라인 파이프[/color][/font_size]
덱을 [b]섞지 않습니다.[/b] 카드 순서가 항상 공개되어 [b]다음에 뭐가 올지 미리 압니다.[/b]
쓰거나 버린 카드는 파이프 맨 뒤로 가서 순환합니다. (시작할 때 한 번만 섞임)

[font_size=21][color=eac77a]⚡ AP & 🔥 투기[/color][/font_size]
매 턴 AP 3을 받아 카드 사용에 씁니다.
[b]공격 카드를 쓸 때마다 투기 +1[/b] — 휘두를수록 달아오릅니다. (남은 AP도 투기로)
투기 10이 되면 [b]투기 발산[/b](보스 10 피해 + 방어 10)!

[font_size=21][color=eac77a]💰 골드[/color][/font_size]
재화 카드로 골드를 벌 수 있어요. [b]턴이 끝나면 사라지니[/b] 그 턴에 [color=eac77a]🛒 상점[/color]에서 카드를 사세요.

[font_size=21][color=eac77a]💀 보스 카드덱[/color][/font_size]
보스도 카드를 씁니다. [b]다음 예고[/b]로 다음 행동을, [b]파워 존[/b]의 카운트다운으로 곧 터질 강력한 기술을 미리 보고 대비하세요.
보스 페이즈(1→2→3)가 오를수록 강해집니다.

[font_size=21][color=eac77a]🖱 조작[/color][/font_size]
카드를 [b]드래그[/b]해서:
• 가운데 대결 무대로 → [b]카드 사용[/b]
• 타임라인 파이프로 → [b]그냥 버리기[/b] (효과 없이 뒤로)
• 액티브 슬롯으로 → [b]모듈 장착[/b]

[font_size=21][color=eac77a]📜 기록[/color][/font_size]
전투 중 상단 [color=eac77a]📜 기록[/color] 버튼으로 지금까지 벌어진 일을 다시 볼 수 있어요."

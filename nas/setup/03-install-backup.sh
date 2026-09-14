#!/bin/bash
# /volume1/dss/setup/03-install-backup.sh — 야간 백업 스크립트를 제자리에 두고 한 번 돌려 본다
#
# ── 사람이 실행한다 (02-rehearse.sh 와 같은 SSH 창에서, sudo -i 상태로) ──────
#   bash /volume1/dss/setup/03-install-backup.sh
#
# 그다음 DSM 작업 스케줄러에 등록한다 — 화면 순서는 Claude 가 안내한다.
#
# root 가 돌리는 스크립트라 root 만 고칠 수 있게 둔다. 관리자 계정이 고칠 수 있는
# 파일을 root 가 매일 실행하면, 그 파일이 곧 root 권한의 뒷문이 된다.
set -u
D=/volume1/dss
SRC=$D/setup/backup-nightly.sh
DST=$D/jobs/backup-nightly.sh

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
[ -s "$SRC" ] || { echo "$SRC 가 없습니다. Claude 에게 알려 주세요."; exit 1; }
bash -n "$SRC" || { echo "스크립트 문법 오류. Claude 에게 알려 주세요."; exit 1; }

mkdir -p "$D/jobs"
find "$D/jobs" -exec /usr/syno/bin/synoacltool -del {} \; >/dev/null 2>&1
cp "$SRC" "$DST" && rm -f "$SRC"
chown -R root:root "$D/jobs"; chmod 700 "$D/jobs"; chmod 700 "$DST"
echo "✓ 제자리: $DST ($(stat -c '%U:%G %a' "$DST"))"
echo
echo "── 한 번 돌려 본다"
bash "$DST"; rc=$?
echo
[ $rc = 0 ] && echo "→ 백업 성공. Claude 에게 '끝났어'라고 알려 주세요." \
            || echo "→ 백업에 실패가 있습니다. Claude 에게 알려 주세요."

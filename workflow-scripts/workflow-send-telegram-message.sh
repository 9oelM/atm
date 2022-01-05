#!/bin/bash

# Only to be used inside github actions

STATUS="$1"
MSG="$2"

telegram_msg=`cat <<EOF
ATM NOTIFICATION
- target: ${target}
- GITHUB_WORKFLOW: ${GITHUB_WORKFLOW}
- GITHUB_EVENT_NAME: ${GITHUB_EVENT_NAME}
- GITHUB_JOB: ${GITHUB_JOB}
- custom_job_id: ${CUSTOM_JOB_ID}
- job_step: ${STATUS}
- job_message: 
${MSG}
EOF
`

echo -e "
\`\`\`
${telegram_msg}
\`\`\`
" | telegram -M -
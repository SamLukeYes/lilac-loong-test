#! /usr/bin/env xonsh

from collections import deque
import json
import datetime
import os

$BASE = "release"
$HEAD = "master"
$PR_URL_FILE = f"{$HOME}/.lilac/pr"
$REBUILD_FILE = f"{$HOME}/.lilac/rebuild"

logs = deque(open(f'{$HOME}/.lilac/build-log.json'))
successful = deque()
failed = deque()

def comment(pr, title, body):
    gh pr comment @(pr) --body f"{title}\n{body}"

def detailed_list(summary: str, items: deque[str]) -> str:
    if not items:
        return ""
    _list = "- " + '\n- '.join(items)
    return f"<details><summary>{summary}</summary>\n\n{_list}</details>\n"

def draft_pr():
    gh_pipeline = !(gh pr create --draft --base $BASE --head $HEAD --title $TITLE --body $BODY)
    if gh_pipeline:
        $PR = gh_pipeline.output.rstrip()
        echo $PR
    else:   # PR already exist
        $PR = gh_pipeline.errors.split()[-1]
        comment($PR, $TITLE, $BODY)
        gh pr ready $PR --undo
    echo $PR > $PR_URL_FILE
    touch $REBUILD_FILE

def pop_log():
    return json.loads(logs.pop())

ts = pop_log()['ts']

while (event := (log := pop_log())['event']) != "build start":
    if event == "successful":
        successful.appendleft(log['pkgbase'])
    elif event == "failed":
        failed.appendleft(log['pkgbase'])

$TITLE = f'lilac build {datetime.datetime.fromtimestamp(ts)}'
$BODY = detailed_list(
    f"Successfully built {len(successful)} packages", successful
) + detailed_list(
    f"Failed to build {len(failed)} packages", failed
)

touch $REBUILD_FILE

if not successful:
    if os.path.isfile($REBUILD_FILE):
        $PR = open($PR_URL_FILE).read().strip()
        if failed:
            comment($PR, $TITLE, $BODY)
        gh pr ready $PR
    rm $REBUILD_FILE
else:
    draft_pr()

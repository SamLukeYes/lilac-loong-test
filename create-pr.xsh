#! /usr/bin/env xonsh

from collections import deque
import json
import datetime

$BASE = "release"
$HEAD = "master"

logs = deque(open(f'{$HOME}/.lilac/build-log.json'))
successful = deque()
failed = deque()

def detailed_list(summary: str, items: deque[str]) -> str:
    if not items:
        return ""
    _list = "- " + '\n- '.join(items)
    return f"<details><summary>{summary}</summary>\n\n{_list}</details>\n"

def pop_log():
    return json.loads(logs.pop())

ts = pop_log()['ts']

while (event := (log := pop_log())['event']) != "build start":
    if event == "successful":
        successful.appendleft(log['pkgbase'])
    elif event == "failed":
        failed.appendleft(f"`{log['pkgbase']}`: {log['error']}")

if not successful:
    print('No package was built.')
    exit(1)

# $TEMP = $(mktemp).rstrip()
$TITLE = f'lilac build {datetime.datetime.fromtimestamp(ts)}'
$BODY = detailed_list(
    f"Successfully built {len(successful)} packages", successful
) + detailed_list(
    f"Failed to build {len(failed)} packages", failed
)

gh_pipeline = !(gh pr create --base $BASE --head $HEAD --title $TITLE --body $BODY)

if gh_pipeline:
    $PR = gh_pipeline.output.rstrip()
    echo $PR
else:   # PR already exist
    $PR = gh_pipeline.errors.split()[-1]
    gh pr comment $PR --body f"{$TITLE}\n{$BODY}"

# rm $TEMP
echo $PR > ~/.lilac/pr
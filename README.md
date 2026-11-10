# Approvals, a Runwell plugin

Ask a client to approve something, and get the answer in the portal, for
[Runwell](https://github.com/Martin-Business-Consultants/runwellv2).

## How it works

1. On any task shown to the client, its sidebar has an **Approval** card. Write a line saying what
   you need a yes on (optional) and press **Ask for approval**.
2. The client's people who **can approve** (the switch on a contact), have portal access and see
   that task are emailed, with a button to the task.
3. In the portal the task's side sheet shows **Your approval is needed**, with **Approve** and
   **Ask for changes** (which needs a word on what should change). Tasks waiting on someone are
   also listed at the top of the portal's first page.
4. The answer goes on the task's discussion in their name, so whoever is on the task is notified
   the way they are of any reply, and into the task's history. Under the task's title, on its page
   and in the side panel, a line says where the latest ask stands.

A task has one ask at a time. **Take it back** withdraws one that hasn't been answered; after an
answer you can ask again. Someone at the client who can't approve sees that it's waiting, and who
answered once it is.

Nothing else changes by itself: an approval doesn't move the task's status or close anything.

## For AI

Connected assistants get `ask_for_approval` (confirmed first, since it emails the client),
`withdraw_approval` and `list_approvals`. A client's own assistant gets `portal_approvals` and
`portal_decide_approval`, which it must confirm with the person before answering for their company.

## Installing

In Runwell (5.31 or newer): **Settings › Plugins**, add
`Martin-Business-Consultants/runwell-approvals`, then switch it on. Removing it keeps its table
(`approvals_requests`); the answers already given stay on each task's discussion and history.

## Developing

Clone it beside a Runwell checkout and link it: `bin/rails "plugins:link[../runwell-approvals]"`,
then restart and `bin/rails db:migrate`. See AGENTS.md.

FSL-1.1-MIT, as Runwell is.

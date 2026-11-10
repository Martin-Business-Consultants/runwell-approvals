# Approvals (a Runwell plugin): guide for AI agents

A Rails engine loaded into a Runwell install (README.md says what it does). Run it from a Runwell
checkout with `bin/rails "plugins:link[path]"`. Read Runwell's `docs/plugin-contract.md` (use
nothing of the core's beyond it) and its `AGENTS.md` (the conventions this code follows).

## How it's built

- `Approvals::Request` (`approvals_requests`) is one ask for a client's approval of a task, and
  the only place its rules live. States: pending, then approved or changes_requested (a contact,
  `decide!`) or withdrawn (the team, `withdraw!`); `ask!` starts one. Each verb refuses a move the
  state doesn't allow (`Request::Refused`, with words a person or an agent can act on), and the
  predicates the pages ask first are `refusal_for(task)` and `decidable_by?(contact)`. Views,
  controllers and JSON ask the model; never copy a rule into them
- Who can decide is `Request.approvers_for(task)`: the client's contacts who `can_approve?`, can
  sign in to the portal and see the task (`contact.sees?`, the core's per-contact visibility)
- A decision is also a note on the task's discussion, written in the contact's name: that is how
  the team is told (the core notifies whoever is on the task of a client's reply). Don't add a
  notifier or a second message
- Events on the task: `task.approval_requested`, `task.approved`, `task.changes_requested`,
  `task.approval_withdrawn`
- Slots: `:task_aside` (the Approval card on a task's page), `:task_notice` (the line under its
  title), `:portal_task` (the ask in the portal's side sheet), `:portal_dashboard` (what's waiting
  on this person). The portal form leaves the sheet's frame (`data-turbo-frame="_top"`)
- `Approvals::Mailer#asked` emails approvers, only those the core's `Notice.reachable_contacts`
  says can be reached, and checks again when it's sent

## Rules

- An approval changes nothing else: not the task's status, not its work. If that's wanted, it is a
  setting to add, off by default
- Staff viewing the portal as a contact can't answer (the buttons are off; the core refuses the post)
- Tables are prefixed `approvals_`, point at core records by id, and migrations only add
- Release: bump `lib/approvals/version.rb`, commit, tag `vX.Y.Z`, push the tag

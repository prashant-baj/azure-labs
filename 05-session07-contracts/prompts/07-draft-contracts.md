# Session 7 prompts — it drafts, you find what is wrong

## The contract draft

> Here is our integration decision record for the seam between **[A]** and **[B]**. Draft the
> interface contract: the shape, what each field means in the client's words, the error cases, the
> timing expectations, and the rule for changing it.
> **Mark anything you inferred rather than took from our record.**

## The ADR draft

> Here is our integration decision record. Draft an architecture decision record: context, decision
> in one sentence, the alternatives we rejected with why, and the consequences — including the bad
> ones. Use only what is in our record. **Mark anything you inferred.**

## What a draft always gets wrong — look here first
1. **The error cases.** There will be one, and it will be called "error".
2. **An invented field**, added because most systems have one. Ask which line of your record it came from.
3. **No versioning rule at all**, because nobody asked for one.
4. **The empty case, the very large case, and the one that arrives late.**

Correct it **in the file**, not in the chat. The repository is the record; the conversation is not.

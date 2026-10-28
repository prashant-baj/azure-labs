// TDD on the rule - one example per test, named after it, each seen red first.
import test from 'node:test';
import assert from 'node:assert/strict';
import { monthStatus } from '../src/monthStatus.mjs';

test('RULE-002d no payment leaves the whole dues', () => {
  assert.deepEqual(monthStatus(250000, []), { paid: false, balance: 250000 });
});

test('RULE-002a one payment of the full dues is paid', () => {
  assert.equal(monthStatus(250000, [250000]).paid, true);
});

test('RULE-002b two payments that cover the dues are paid', () => {
  assert.equal(monthStatus(250000, [150000, 100000]).paid, true);
});

test('RULE-002c a part payment shows the balance', () => {
  assert.deepEqual(monthStatus(250000, [100000]), { paid: false, balance: 150000 });
});

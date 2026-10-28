// Thin steps: they turn words into calls and compare. The rule lives in src/, never here.
import assert from 'node:assert/strict';
import { Given, When, Then } from '@cucumber/cucumber';
import { monthStatus } from '../src/monthStatus.mjs';

const paise = (rupees) => Number(rupees) * 100;
const amounts = (text) => (text === 'nothing' ? [] : text.split('+').map((p) => paise(p.trim())));

Given('the dues for the month are {int}', function (dues) {
  this.dues = paise(dues);
});

Given('the flat has paid {}', function (payments) {
  this.payments = amounts(payments);
});

When('the treasurer checks the month', function () {
  this.status = monthStatus(this.dues, this.payments);
});

Then('the flat is {} with a balance of {int}', function (status, balance) {
  assert.equal(this.status.paid, status === 'paid');
  assert.equal(this.status.balance, paise(balance));
});

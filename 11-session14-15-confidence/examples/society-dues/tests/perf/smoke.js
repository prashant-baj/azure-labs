// Performance smoke - after every deploy to the test environment. Not a load test: a few users, a short
// time, and the NFR thresholds. If a threshold breaks, k6 exits non-zero and the pipeline stops.
// Thresholds come from the spec (NFR-001) through the pipeline variables P95_MS and ERROR_RATE.
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.BASE_URL || 'http://localhost:8000';
const JSON_HEADERS = { 'Content-Type': 'application/json' };

export const options = {
  scenarios: {
    smoke: { executor: 'constant-vus', vus: Number(__ENV.VUS || 5), duration: __ENV.DURATION || '30s' },
  },
  thresholds: {
    'http_req_duration{name:reminders}': [`p(95)<${__ENV.P95_MS || 2000}`], // NFR-001: the dues answer
    http_req_failed: [`rate<${__ENV.ERROR_RATE || 0.01}`],
    checks: ['rate>0.99'],
  },
};

export default function () {
  const list = http.get(`${BASE}/reminders`, { headers: { 'X-Role': 'treasurer' }, tags: { name: 'reminders' } });
  check(list, { 'reminders answered': (r) => r.status === 200 });

  const ref = `K6-${__VU}-${__ITER}-${Date.now()}`;
  const body = JSON.stringify({ bank_reference: ref, remark: 'C-101', payer: 'Ravi', amount: '10' });
  const paid = http.post(`${BASE}/payments/upi`, body, { headers: JSON_HEADERS, tags: { name: 'upi' } });
  check(paid, { 'payment recorded': (r) => r.status === 201 });
  sleep(1);
}

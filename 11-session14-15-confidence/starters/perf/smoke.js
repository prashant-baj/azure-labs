// Performance smoke - after every deploy to the test environment (verify:perf). A few users, a short time,
// the NFR thresholds from your test strategy (P95_MS, ERROR_RATE - the pipeline passes them in).
// Change PATHS to the requests your NFR is about - the answer a user waits for, not just /health.
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.BASE_URL || 'http://localhost:8000';
const PATHS = (__ENV.PERF_PATHS || '/health').split(',');   // e.g. "/api/orders?status=open,/api/orders/42"

export const options = {
  scenarios: { smoke: { executor: 'constant-vus', vus: Number(__ENV.VUS || 5), duration: __ENV.DURATION || '30s' } },
  thresholds: {
    http_req_duration: [`p(95)<${__ENV.P95_MS || 2000}`],   // NFR-0nn
    http_req_failed: [`rate<${__ENV.ERROR_RATE || 0.01}`],   // NFR-0nn
    checks: ['rate>0.99'],
  },
};

export default function () {
  for (const path of PATHS) {
    const r = http.get(`${BASE}${path}`, { tags: { name: path } });
    check(r, { [`${path} answered`]: (x) => x.status === 200 });
  }
  sleep(1);
}

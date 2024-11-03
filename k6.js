import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    scenarios: {
        high_load_test: {
            executor: 'constant-arrival-rate',
            rate: 40000,   // Number of iterations (requests) per second
            timeUnit: '1s', // The unit of time in which the rate is defined
            duration: '30s', // Total duration of the scenario run
            preAllocatedVUs: 1, // Initial number of VUs to be allocated
            maxVUs: 1000, // Maximum number of VUs allowed for the test
        },
    },
};

export default function () {
    const res = http.get('http://139.162.140.217/');
    check(res, { 'status was 200': (r) => r.status == 200 });
}
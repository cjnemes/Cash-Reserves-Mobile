# Testing Strategy

Goals
- Ensure Swift engine (Allocator, Rebalancer, Forecaster) matches Python behavior.
- Verify Plan JSON compatibility.

Plan
- Create a unit test target in Xcode.
- Load fixtures in `fixtures/` and decode into `Plan`.
- Run algorithms and compare results to expected JSON fixtures (rounded to 2 decimals).

Fixtures
- `fixtures/plan_sample.json`
- `fixtures/expected_allocation_1000.json`
- `fixtures/expected_detailed_allocation_1000.json`
- `fixtures/expected_rebalancing.json`

Example (pseudocode)
```
let url = Bundle.module.url(forResource: "plan_sample", withExtension: "json", subdirectory: "fixtures")!
let data = try Data(contentsOf: url)
let plan = try JSONDecoder().decode(Plan.self, from: data)
let moves = Allocator.allocationPlan(plan, newCash: 1000)
// Compare to expected JSON
```

Notes
- Use 2-decimal comparisons for money values.
- Avoid floating-point noise by rounding before comparing.


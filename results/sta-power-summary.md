# Static timing and power summary

## Timing

- Tool: Synopsys PrimeTime
- Clock constraint: 15.00 ns
- Worst max path: `lat_addr_q_reg[3]` → `mem_reg[4][1]`
- Data arrival: 1.42 ns
- Data required: 14.94 ns
- Setup slack: +13.52 ns
- Indicative reciprocal of derived 1.48 ns period: approximately 675.7 MHz

The frequency value is report-derived and is not claimed as signoff post-parasitic Fmax.

## Power

- Net switching: 133.0 µW
- Cell internal: 20.71 µW
- Cell leakage: 0.1044 µW
- Total: 153.8 µW

The retained analysis did not annotate VCD/SAIF activity, so these are vectorless estimates.

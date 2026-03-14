[root](../../../README.md) / [scenes](../../README.md) / [vehicles](../README.md) / civilian

# Civilian Vehicle Scene

`civilian_vehicle.tscn` is the baseline drivable vehicle for the MVP.

Responsibilities:

- vehicle collision
- placeholder visuals
- handling owned by `scripts/vehicles/vehicle_controller.gd`

Additional vehicle types should derive from this pattern, with tuning differences pushed into data where practical.

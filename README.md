# librato_stats_gpu #

Small gem to find nvidia-smi in path and parse the csv output for GPU stats and push those stats into librato. All using ruby std-lib, i.e without any ruby dependencies.

## Installation ##

Fork this repo from github and build the gem with:
```shellsession
$ gem build librato_stats_gpu.gemspec
```

Then install the built gem with:
```shellsession
$ gem install librato_stats_gpu-<version>.gem
```

## Usage ##

As root execute the following:
```shellsession
# librato_stats_gpu
```
it will default configuration to `librato_stats_gpu.yml`

else run the following for alternative configuration names and paths:

```shellsession
# librato_stats_gpu [path_to_configuration_filename.yml]
```

Then setup crontab to run it at desired interval

## Configuration ##

Create a file named `librato_stats_gpu.yml` in the current cwd with the following content
```yaml
url: https://metrics-api.librato.com/v1/metrics
username: username@example.com
api_token: xxxx_LIBRATO_API_TOKEN_HERE_xxxx
```

Or you can add `fields` array to override the default metrics. see `nvidia-smi --help-query-gpu` for available fields
```yaml
url: https://metrics-api.librato.com/v1/metrics
username: username@example.com
api_token: xxxx_LIBRATO_API_TOKEN_HERE_xxxx
fields:
  - utilization.gpu
  - utilization.memory
  - temperature.gpu
```

default for `fields` is:

    pcie.link.gen.current
    pcie.link.gen.max
    pcie.link.width.current
    pcie.link.width.max
    utilization.gpu
    utilization.memory
    memory.total
    memory.used
    memory.free
    temperature.gpu
    fan.speed
    power.management
    power.draw
    power.limit
    enforced.power.limit
    power.default_limit
    power.min_limit
    power.max_limit
    clocks.current.graphics
    clocks.max.graphics
    clocks.current.sm
    clocks.max.sm
    clocks.current.memory
    clocks.max.memory
    clocks_throttle_reasons.applications_clocks_setting
    clocks_throttle_reasons.sw_power_cap
    clocks_throttle_reasons.hw_slowdown
    clocks_throttle_reasons.unknown
    ecc.mode.current
    ecc.mode.pending
    ecc.errors.corrected.volatile.device_memory
    ecc.errors.corrected.volatile.register_file
    ecc.errors.corrected.volatile.l1_cache
    ecc.errors.corrected.volatile.l2_cache
    ecc.errors.corrected.volatile.texture_memory
    ecc.errors.corrected.volatile.total
    ecc.errors.corrected.aggregate.device_memory
    ecc.errors.corrected.aggregate.register_file
    ecc.errors.corrected.aggregate.l1_cache
    ecc.errors.corrected.aggregate.l2_cache
    ecc.errors.corrected.aggregate.texture_memory
    ecc.errors.corrected.aggregate.total
    ecc.errors.uncorrected.volatile.device_memory
    ecc.errors.uncorrected.volatile.register_file
    ecc.errors.uncorrected.volatile.l1_cache
    ecc.errors.uncorrected.volatile.l2_cache
    ecc.errors.uncorrected.volatile.texture_memory
    ecc.errors.uncorrected.volatile.total
    ecc.errors.uncorrected.aggregate.device_memory
    ecc.errors.uncorrected.aggregate.register_file
    ecc.errors.uncorrected.aggregate.l1_cache
    ecc.errors.uncorrected.aggregate.l2_cache
    ecc.errors.uncorrected.aggregate.texture_memory
    ecc.errors.uncorrected.aggregate.total
    retired_pages.single_bit_ecc.count
    retired_pages.double_bit.count
    retired_pages.pending

Some value mapping will occur for some values:

| String values from nvidia-smi   | Value |
| :------------------------------ | ----: |
| `Not Active`  `Disabled`  `No`  | 0     |
| `Active`      `Enabled`   `Yes` | 1     |

Also `[Not Supported]` returned from nvidia-smi will skip reporting that metric

## TODO ##

???

rename GPU class to nvidia and inherit a GPU base class?

support AMD/ATI?

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jesperrojestal/librato_stats_gpu.

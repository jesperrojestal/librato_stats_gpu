# librato_stats_gpu #

Small gem to find nvidia-smi in path and parse the csv output for GPU stats and push those stats into librato.

## Installation ##

Fork this repo from github and build the gem with:
```shellsession
gem build librato_stats_gpu.gemspec
```

Then install the built gem with:
```shellsession
gem install librato_stats_gpu-<version>.gem
```

## Usage ##

As root execute the following:
```shellsession
# librato_stats_gpu
```
it will default configuration to librato_stats_gpu.yml

else run the following for alternative names:

```shellsession
# librato_stats_gpu [path_to_configuration_filename.yml]
```

Then setup crontab to run it at desired interval

## Configuration ##

Create a file named librato_stats_gpu.yml in the current cwd with the following content

```yaml
url: https://metrics-api.librato.com/v1/metrics
username: username@example.com
api_token: xxxx_LIBRATO_API_TOKEN_HERE_xxxx
```

Or you can add 'fields' array to specify your own metrics. see 'nvidia-smi --help-query-gpu' for available
```yaml
url: https://metrics-api.librato.com/v1/metrics
username: username@example.com
api_token: xxxx_LIBRATO_API_TOKEN_HERE_xxxx
fields:
  - utilization.gpu
  - utilization.memory
  - temperature.gpu
```

default for fields is:

    pcie.link.gen.current
    pcie.link.gen.max
    pcie.link.width.current
    pcie.link.width.max
    utilization.gpu
    utilization.memory
    temperature.gpu
    power.draw
    power.min_limit
    power.max_limit
    clocks.current.graphics
    clocks.max.graphics
    clocks.current.sm
    clocks.max.sm
    clocks.current.memory
    clocks.max.memory


## TODO ##

???
rename GPU class to nvidia and inherit a GPU base class?
support AMDTI?

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jesperrojestal/librato_stats_gpu.

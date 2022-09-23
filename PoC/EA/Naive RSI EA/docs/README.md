# NAIVE RSI EA

# Indicators
```
> RSI Indicator with period 9
```

# Strategy
```
On Init
> Initialize an RSI Indicator 

Do the following every tick
> If no new bar has appeared, skip the following steps
> Fetch last 18 periods of data
> Calculate Moving Average of last 18 RSIs (moving_average_9) and last 9 RSIs (moving_average_18)
> Evaluate conditions (given below)
> Long/Short or Buy/Sell based on the conditions
```

## Buy Condition
```
rsi_value > MAX( moving_average_9, moving_average_18 )
```

## Sell Condition
```
rsi_value < MIN( moving_average_9, moving_average_18 )
```

## Exit Long Condition
```
rsi_value <= moving_average_9
```

## Exit Short Condition
```
rsi_value >= moving_average_9
```


# Test Results

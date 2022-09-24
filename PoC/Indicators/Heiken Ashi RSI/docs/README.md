# Heiken Ashi RSI

## Indicator for calculating RSI values on Heiken Ashi 
[heiken-ashi-rsi](heiken_ashi_rsi.mq5) is the actual indicator
[heiken-ashi-close](heiken_ashi_close.mq5) is for testing purposes

## Testing the correctness
```
> Create new mq5 files named heiken_ashi_rsi.mq5 and heiken_ashi_close.mq5 in Meta Editor (under Indicators folder)
> Paste code from relevant indicators
> Compile both indicators
> Create new chart in MT5
> Drag and drop heiken_ashi_rsi on the chart ( set the RSIPeriod )
> Drag and drop heiken_ashi_close on the chart
> Both should appear on different indicator windows
> On the heiken_ashi_close indicator window, drag and drop the 'Relative Strength Index' from Indicators/Oscillators (with same RSIPeriod) and set "Apply to" as "Previous Indicator's Data"
> The RSI indicator and the Heiken-Ashi-RSI Indicator should have the same values
```

## Inputs
```
InpPeriodRSI = period for calculating RSI values
price_type = ENUM_APPLIED_PRICE_TYPE (PRICE_OPEN, PRICE_HIGH, PRICE_LOW, PRICE_CLOSE) [only these four are allowed]
```


## Usage
```
```

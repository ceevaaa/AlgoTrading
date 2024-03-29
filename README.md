# Algo Trading

> **There is an old joke that the best systematic trading setup consists of a computer, a man and a dog. The computer runs a fully automated strategy, the man feeds the dog, and the dog bites the man if he touches the computer.**

> **Put yourselves in shoes of the Big Hedge Funds and also in the shoes of Retail Traders**

# Tenets
1. **Thou shall be desciplined.**
2. Thou shall never skip SL.
3. Thou shall never over leverage.
4. Thou shall not be greedy.
5. Thou shall always trust the EA. 
6. Thou shall only trade own money.
7. Thou shall always backtest.

<br>

# Index

| Name       	| Location                          	|
|------------	|-----------------------------------	|
| PoC        	| [ Index ]( /PoC/README.md )       	|
| Strategies 	| [Index](/strategies/README.md)    	|
| Libraries  	| [ Index ]( /Libraries/README.md ) 	|


<br>

# Links/Notes

Reference: https://drive.google.com/drive/folders/1ZwVVrJhy697Hwl90r_DFcJGn0wnaIrMJ

pandas-ta: https://github.com/twopirllc/pandas-ta

Risk Calculation: https://www.mql5.com/en/forum/312990, https://www.mql5.com/en/code/19870

MQL5 Project Structure: https://www.mql5.com/en/articles/7863

MQL5 Price Action: https://www.mql5.com/en/articles/1771

MQL5 Testing Fundamentals: https://www.mql5.com/en/articles/239

MARGIN/LOT SIZE SORTED - https://www.mql5.com/en/forum/312990

Error Handling in trade calls: https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctraderesultretcode, https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes (use for positionopen, positionclose etc )

ATR Indicator: https://www.earnforex.com/guides/average-true-range/

MQL5 Cookbook: https://www.mql5.com/en/articles/638

EA Trading engine 4 Vladimir Karputov: article-> https://www.mql5.com/en/articles/9717, code-> https://www.mql5.com/ru/code/37813

EA-USING-VOLUMES: https://www.mql5.com/en/articles/11050#system

MQL5-ERRORS : https://www.mql5.com/en/docs/constants/errorswarnings/errorcodes , https://www.mql5.com/en/articles/2041

ACCOUNT-INFO [Margin, Leverage etc] : https://www.mql5.com/en/docs/standardlibrary/tradeclasses/caccountinfo

**Bot Checks (Before Publishing in the Market): https://www.mql5.com/en/articles/2555**

**RISK MANAGEMENT (concepts) https://www.earnforex.com/guides/forex-risk-management/**

Guides: https://www.earnforex.com/guides

EVENT HANDLERS - https://www.mql5.com/en/docs/event_handlers

OPTIMIZATION - https://www.mql5.com/en/articles/1052

USE OF #RESOURCE - https://www.mql5.com/en/articles/261

MARGIN JARGON CHEAT SHEET - https://www.babypips.com/learn/forex/margin-cheat-sheet

MQL5-Baap/God: https://github.com/kenorb 

How to start with MQL5: https://www.mql5.com/en/forum/296230

MQL Coding Techniques, Multi-symbol EA: https://www.youtube.com/playlist?list=PLv-cA-4O3y95e9N3saUmDpQGKR11k-v1B

Trailing-Stop-On-Profit EA: https://github.com/EarnForex/Trailing-Stop-on-Profit/blob/main/MQL5/Experts/Trailing%20Stop%20on%20Profit.mq5

Heiken Ashi EA: https://github.com/EarnForex/Heiken-Ashi-Naive , docs: https://www.earnforex.com/metatrader-expert-advisors/Heiken-Ashi-Naive/

CTrade beginner tutorial: https://www.mql5.com/en/articles/481


## CTrade Articles ( Parser Bolte )
<html>
<p><a href="https://www.mql5.com/en/articles/5654" target="_blank">Part 1. Concept, data management</a><br> <a href="https://www.mql5.com/en/articles/5669" target="_blank">Part 
    2. Collection of historical orders and deals</a><br> <a href="https://www.mql5.com/en/articles/5687" target="_blank">Part 3. Collection of market orders 
    and positions, arranging the search</a><br> <a href="https://www.mql5.com/en/articles/5724" target="_blank">Part 4. Trading events. Concept</a><br> 
    <a href="https://www.mql5.com/en/articles/6211" target="_blank">Part 5. Classes and collection of trading events. Sending events to the program</a><br> <a href="https://www.mql5.com/en/articles/6383" target="_blank">Part 
    6. Netting account events</a><br> <a href="https://www.mql5.com/en/articles/6482" target="_blank">Part 7. StopLimit order activation events, preparing 
    the functionality for order and position modification events</a><br> <a href="https://www.mql5.com/en/articles/6595" target="_blank">Part 8. Order and 
    position modification events</a><br> <a href="https://www.mql5.com/en/articles/6651" target="_blank">Part 9. Compatibility with MQL4 — Preparing data</a><br> 
    <a href="https://www.mql5.com/en/articles/6767" target="_blank">Part 10. Compatibility with MQL4 - Events of opening a position and activating pending 
    orders</a><br> <a href="https://www.mql5.com/en/articles/6921" target="_blank">Part 11. Compatibility with MQL4 - Position closure events</a><br> 
    <a href="https://www.mql5.com/en/articles/6952" target="_blank">Part 12. Account object class and account object collection</a><br> <a href="https://www.mql5.com/en/articles/6995" target="_blank">Part 
    13. Account object events</a><br> <a href="https://www.mql5.com/en/articles/7014" target="_blank">Part 14. Symbol object</a><br> <a href="https://www.mql5.com/en/articles/7041" target="_blank">Part 
    15. Symbol object collection</a><br> <a href="https://www.mql5.com/en/articles/7071" target="_blank">Part 16. Symbol collection events</a><br> 
    <a href="https://www.mql5.com/en/articles/7124" target="_blank">Part 17. Interactivity of library objects</a><br> <a href="https://www.mql5.com/en/articles/7149" target="_blank">Part 
    18. Interactivity of account and any other library objects</a><br> <a href="https://www.mql5.com/en/articles/7176" target="_blank">Part 19. Class of 
    library messages</a><br> <a href="https://www.mql5.com/en/articles/7195" target="_blank">Part 20. Creating and storing program resources</a><br> 
    <a href="https://www.mql5.com/en/articles/7229" target="_blank">Part 21. Trading classes - Base cross-platform trading object</a><br> <a href="https://www.mql5.com/en/articles/7258" target="_blank">Part 
    22. Trading classes - Base trading class, verification of limitations</a><br> <a href="https://www.mql5.com/en/articles/7286" target="_blank">Part 23. 
    Trading classes - Base trading class, verification of valid parameters</a><br> <a href="https://www.mql5.com/en/articles/7326" target="_blank">Part 24. 
    Trading classes - Base trading class, auto correction of invalid parameters</a><br> <a href="https://www.mql5.com/en/articles/7365" target="_blank">Part 
    25. Trading classes - Base trading class, handling errors returned by the trade server</a><br> <a href="https://www.mql5.com/en/articles/7394" target="_blank">Part 
    26. Working with pending trading requests - First implementation (opening positions)</a><br> <a href="https://www.mql5.com/en/articles/7418" target="_blank">Part 
    27. Working with pending trading requests - Placing pending orders</a><br> <a href="https://www.mql5.com/en/articles/7438" target="_blank">Part 28. 
    Working with pending trading requests - Closure, removal and modification</a><br> <a href="https://www.mql5.com/en/articles/7454" target="_blank">Part 
    29. Working with pending trading requests - request object classes</a><br> <a href="https://www.mql5.com/en/articles/7481" target="_blank">Part 30. 
    Pending trading requests - managing request objects</a><br> <a href="https://www.mql5.com/en/articles/7521" target="_blank">Part 31. Pending trading 
    requests - opening positions under certain conditions</a><br> <a href="https://www.mql5.com/en/articles/7536" target="_blank">Part 32. Pending trading 
    requests - placing pending orders under certain conditions</a><br> <a href="https://www.mql5.com/en/articles/7554" target="_blank">Part 33. Pending 
    trading requests - closing positions (full, partial or by an opposite one) under certain conditions</a><br></p>
</html>


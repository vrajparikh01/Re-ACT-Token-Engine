# 📘 Re:ACT Cycle Engine
A Hook-Driven, Swap-Reactive Token Flow System for Uniswap v4

## 🚀 Overview

The Re:ACT Cycle Engine (RCE) introduces a fully on-chain, swap-reactive token flow mechanism designed specifically for Uniswap v4 hooks. Instead of relying on predictable unlock schedules or centralized vesting logic, RCE uses a 5-phase reactive cycle that progresses every time a BUY swap occurs on the hooked pool.

This creates a token economy where:
- Unlocks happen only during real market activity
- Stabilizing sells are triggered only when the cycle dictates
- Liquidity reinforcement occurs every 5th buy
- Treasury reserves grow organically through LP token economics
- Investors receive RLIQ Series Tokens representing token-side claims on injected liquidity

All logic occurs inside the v4 hook, making the entire system transparent, trustless, and dependent only on actual swap activity.

RCE is optimized for projects that want:
✔ Sustainable unlock schedules
✔ Anti-dump supply flow
✔ On-chain transparency
✔ Programmatic liquidity reinforcement
✔ Cycle-based token distribution
✔ No external executors or cron jobs

## ⚙️ Core Idea

Every BUY swap advances the engine to the next phase of the Re:ACT Cycle:
Buy #1 → Activate Tokens  
Buy #2 → Stabilizing Sell  
Buy #3 → Activate Tokens  
Buy #4 → Stabilizing Sell  
Buy #5 → Liquidity Reinforcement Event (LRE)
After the 5th buy, the cycle resets to phase 1.

This predictable but market-dependent structure makes token flow:

• Reactive
• Controlled
• Transparent
• Sustainable

without requiring complex math or volatile indicators.

## 🔄 Atomic Actions (10-Point Version)

These describe the full behavior of the engine in precise, judge-friendly, hackathon-ready language.

1. The hook monitors every BUY swap in the pool.
Each BUY increments the internal cycle counter from 1 → 5.

2. On Cycle Phase 1 (Buy #1), a portion of locked tokens is activated.
A fraction of the buy amount is moved from Dormant Supply to Active Cycle Supply.

3. On Cycle Phase 2 (Buy #2), the Active Cycle Supply is sold back into the pool.
The resulting USDC accumulates in the Stability Reservoir.

4. On Cycle Phase 3 (Buy #3), new tokens are activated again.
This ensures no unlocks occur without market activity.

5. On Cycle Phase 4 (Buy #4), the newly activated tokens are sold.
Again, all USDC goes to the Stability Reservoir.

6. On Cycle Phase 5 (Buy #5), the engine performs a Liquidity Reinforcement Event (LRE).
All stored USDC from the reservoir is paired with newly unlocked tokens to create fresh LP.

7. LP tokens from every LRE are wrapped into RLIQ Series Tokens.
Each completed cycle mints a new series:
RLIQ-1, RLIQ-2, RLIQ-3, …

8. RLIQ Series Tokens represent the TOKEN-side claim on that specific LP.
USDC from LP withdrawals always goes to the Treasury.

9. RLIQ Vesting Windows:
50% unlockable after 30 days
Remaining 50% unlockable after 75 days

10. The Treasury uses accumulated USDC for controlled buybacks during significant price drops.
Team withdrawals are limited and rate-controlled to maintain alignment with users.

## 🧩 System Components

| Component                  | Description                                                                    |
| -------------------------- | ------------------------------------------------------------------------------ |
| **ReActCycleHook.sol**     | The main Uniswap v4 hook that manages cycle phases and executes atomic actions |
| **TokenVault.sol**         | Stores the dormant/locked token supply                                         |
| **StabilityReservoir.sol** | Holds USDC from Phase 2 and Phase 4 stabilizing sells                          |
| **RLIQ.sol (ERC-1155)**    | Represents LP claim tokens for each cycle series                               |
| **Treasury.sol**           | Stores USDC from LP redemptions and executes buybacks                          |
| **Config.sol**             | Parameter storage (percent activation, sell ratio, vesting durations)          |

## 🧨 Uniswap v4 Hook Architecture

The Re:ACT Cycle Engine is implemented entirely through a custom Uniswap v4 hook, leveraging the v4 permissionless architecture to execute token-economic logic inside the swap lifecycle.
The hook integrates with the pool through the following key callbacks:

### 1. afterSwap()

The core of the engine — this is where each cycle action happens.
On each BUY:
- Increment cycle counter
- Execute one of:
  - Token Activation (Phases 1 & 3)
  - Stabilizing Sell (Phases 2 & 4)
  - Liquidity Reinforcement Event → LP Mint → RLIQ (Phase 5)
- Log events for indexing
- Reset counter after Phase 5

This callback is wrapped inside the pool manager’s lock() mechanism to ensure atomicity and safety.

### 2. Internal Hook Storage & Accounting

The hook uses its own internal storage for:
Cycle phase counter (1 → 5)
- Activated token amount
- Reservoir USDC balance
- Cycle ID (for RLIQ series)
- Vesting timestamps
- LP mapping for each RLIQ series

All state changes are deterministic and dependent only on the swaps occurring in the pool.

### 3. PoolManager Locking

Every write action (sell, unlock, LP mint) is performed inside:
PoolManager.Lock.lock(...)

This ensures:
- Reentrancy safety
- Unified execution context
- Guaranteed state correctness
- Hook-driven atomic state transitions

### 4. LP Minting & RLIQ Wrapping

During Phase 5:
1. The hook mints new LP using Reservoir USDC + newly unlocked tokens
2. LP NFT is transferred to the hook
3. The hook mints RLIQ-X ERC-1155 tokens to whitelisted investors
4. The LP NFT is held internally until RLIQ redemption

This creates a fully traceable, cycle-indexed liquidity reinforcement system.

## 🌐 Why v4 Hooks Make This Possible

Uniswap v4 allows hooks to be injected directly into the swap execution sequence.
This gives the protocol full control over:
- swap-triggered logic
- internal accounting
- conditional unlocks
- reactive liquidity mechanics
- LP creation
- vesting operations

No oracles.
No keepers.
No external executors.

Everything occurs because users trade.

## 📦 Development (Eth Seploia Testnet)

- git clone https://github.com/vrajparikh01/Re-ACT-Token-Engine 
- forge build
- forge script script/01_DeployHook.s.sol --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
- Tests are very minimal for this hook project because I was concentrating on designing the protocol and hook so will work on tests after the hookathon and make it live

#### Check the testnet transactions of hook on this address: 0xfecea7b046b4daface340c7a2fe924cf41b6d274

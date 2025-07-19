# VaultWorks - Autonomous Treasury Management Protocol

[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-purple)](https://stacks.co)
[![Clarity](https://img.shields.io/badge/Language-Clarity-blue)](https://clarity-lang.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## Overview

VaultWorks is a cutting-edge autonomous treasury management system that transforms how decentralized organizations handle collective funds. Built on the Stacks blockchain and secured by Bitcoin's network, VaultWorks combines institutional-grade security with community-driven governance, creating a trustless environment where stakeholders collaboratively manage shared resources through democratic consensus mechanisms.

## Key Features

- **🏛️ Advanced Stake-Weighted Governance** - Proportional representation ensuring fair decision-making
- **🔒 Multi-Layered Security Architecture** - Time-locked safeguards preventing flash attacks
- **🤖 Autonomous Proposal Lifecycle** - Built-in fraud prevention and automated execution
- **💧 Dynamic Liquidity Management** - Intelligent rebalancing mechanisms
- **📊 Transparent Fund Allocation** - Immutable audit trails for all transactions
- **🛡️ Anti-Manipulation Defenses** - Sophisticated protection against coordinated attacks

## System Overview

VaultWorks operates as a decentralized autonomous organization (DAO) treasury management system where:

1. **Stakeholders** deposit STX tokens to receive governance tokens
2. **Proposals** are created for fund allocation decisions
3. **Voting** occurs using stake-weighted democratic mechanisms
4. **Execution** happens automatically when consensus is reached

## Contract Architecture

### Core Components

#### 1. Staking System

- **Deposit Mechanism**: Users stake STX to receive 1:1 governance tokens
- **Lock Period**: Security feature preventing immediate withdrawals (≈10 days)
- **Withdrawal Process**: Time-locked withdrawals with proportional token burning

#### 2. Governance Framework

- **Proposal Creation**: Stakeholders can create funding proposals
- **Voting System**: Stake-weighted voting with anti-manipulation safeguards
- **Execution Engine**: Automatic execution of approved proposals

#### 3. Security Features

- **Time Locks**: Prevent flash loan attacks and hasty decisions
- **Access Controls**: Owner-only initialization and validation checks
- **Balance Verification**: Comprehensive balance and authorization checks

### Data Structures

```clarity
;; Stakeholder balances (governance tokens)
balances: principal -> uint

;; Deposit records with security metadata
deposits: principal -> {
  amount: uint,
  lock-until: uint,
  last-reward-block: uint
}

;; Governance proposals
proposals: uint -> {
  proposer: principal,
  description: string-ascii,
  amount: uint,
  target: principal,
  expires-at: uint,
  executed: bool,
  yes-votes: uint,
  no-votes: uint
}

;; Voting records
votes: {proposal-id: uint, voter: principal} -> bool
```

## Data Flow

### 1. Staking Flow

```
User STX → Contract Vault
     ↓
Governance Tokens ← User Balance
     ↓
Lock Period Activated
```

### 2. Proposal Flow

```
Stakeholder Creates Proposal
     ↓
Community Voting Period
     ↓
Majority Consensus Check
     ↓
Automatic Execution (if approved)
```

### 3. Withdrawal Flow

```
User Initiates Withdrawal
     ↓
Lock Period Validation
     ↓
Token Burning & STX Return
```

## API Reference

### Public Functions

#### `initialize()`

Initializes the protocol (owner-only).

#### `deposit(amount: uint)`

Stake STX tokens to receive governance tokens.

- **Parameters**: `amount` - STX amount in microSTX
- **Returns**: Success confirmation
- **Requirements**: Amount ≥ minimum deposit (1 STX)

#### `withdraw(amount: uint)`

Withdraw staked STX after lock period.

- **Parameters**: `amount` - STX amount to withdraw
- **Returns**: Success confirmation
- **Requirements**: Lock period expired, sufficient balance

#### `create-proposal(description, amount, target, duration)`

Create a new governance proposal.

- **Parameters**:
  - `description` - Proposal description (max 256 chars)
  - `amount` - Funding amount requested
  - `target` - Recipient address
  - `duration` - Voting period (144-20160 blocks)
- **Returns**: Unique proposal ID

#### `vote(proposal-id: uint, vote-for: bool)`

Cast a stake-weighted vote on a proposal.

- **Parameters**:
  - `proposal-id` - ID of proposal to vote on
  - `vote-for` - true for yes, false for no
- **Returns**: Success confirmation

#### `execute-proposal(proposal-id: uint)`

Execute an approved proposal.

- **Parameters**: `proposal-id` - ID of proposal to execute
- **Returns**: Success confirmation
- **Requirements**: Majority approval, voting period ended

### Read-Only Functions

#### `get-balance(account: principal)`

Get governance token balance for an account.

#### `get-total-supply()`

Get total circulating governance tokens.

#### `get-proposal(proposal-id: uint)`

Get detailed proposal information.

#### `get-deposit-info(account: principal)`

Get staking information for an account.

#### `get-vote(proposal-id: uint, voter: principal)`

Get voting record for a specific proposal and voter.

## Security Considerations

### Time-Lock Mechanisms

- **Deposit Lock Period**: ≈10 days (1440 blocks)
- **Voting Duration**: 1-14 days (144-20160 blocks)
- **Flash Attack Prevention**: Immediate withdrawals blocked

### Access Controls

- **Owner Initialization**: Only contract owner can initialize
- **Stakeholder Proposals**: Only token holders can create proposals
- **Voting Rights**: Proportional to stake amount

### Anti-Manipulation Features

- **One Vote Per Proposal**: Prevents double voting
- **Stake-Weighted Voting**: Prevents Sybil attacks
- **Proposal Validation**: Comprehensive input validation

## Getting Started

### Prerequisites

- Stacks wallet with STX tokens
- Understanding of Clarity smart contracts
- Node.js and npm (for testing)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yushau-alabi/vault-works.git
cd vault-works
```

2. Install dependencies:

```bash
npm install
```

3. Run tests:

```bash
npm test
```

4. Check contract validity:

```bash
clarinet check
```

### Deployment

1. Configure your deployment settings in `settings/`
2. Deploy using Clarinet:

```bash
clarinet deploy --network testnet
```

## Testing

The project includes comprehensive test coverage:

```bash
# Run all tests
npm test

# Check contract syntax
clarinet check

# Run specific test file
npm run test -- vault-works.test.ts
```

## Governance Parameters

| Parameter | Value | Description |
|-----------|--------|-------------|
| Minimum Deposit | 1 STX | Minimum stake required |
| Lock Period | ~10 days | Security lock for deposits |
| Min Voting Duration | 1 day | Minimum proposal voting period |
| Max Voting Duration | 14 days | Maximum proposal voting period |

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `err-owner-only` | Function restricted to contract owner |
| u101 | `err-not-initialized` | Contract not yet initialized |
| u103 | `err-insufficient-balance` | Insufficient token balance |
| u105 | `err-unauthorized` | Unauthorized access attempt |
| u107 | `err-proposal-expired` | Proposal voting period ended |
| u108 | `err-already-voted` | User already voted on proposal |
| u110 | `err-locked-period` | Tokens still in lock period |

## Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting PRs.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Roadmap

- [ ] Multi-signature proposal execution
- [ ] Cross-chain asset management
- [ ] Advanced governance mechanisms
- [ ] Integration with DeFi protocols
- [ ] Mobile wallet support

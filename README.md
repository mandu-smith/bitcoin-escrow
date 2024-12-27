# Bitcoin Escrow Smart Contract

A secure, decentralized escrow service implemented as a smart contract for Bitcoin transactions with built-in dispute resolution capabilities.

## Overview

This smart contract provides a trustless escrow service for Bitcoin transactions, featuring:

- Secure fund management
- Built-in dispute resolution system
- Professional arbitration services
- Configurable timeouts
- Automated fee handling
- Comprehensive security measures

## Features

### Core Functionality

- **Escrow Creation**: Sellers can create escrow accounts with specified buyers and amounts
- **Fund Management**: Secure handling of locked funds with automated releases
- **Dispute Resolution**: Built-in arbitration system for conflict resolution
- **Timeout Mechanism**: Automatic refund capability after timeout period
- **Fee Structure**: Configurable arbitrator fees with automatic distribution

### Security Features

- Role-based access control
- Strict validation checks
- Timeout protection
- Secure fund handling
- State machine implementation

## Technical Architecture

### Constants

```clarity
ERR_NOT_AUTHORIZED (u100)
ERR_INVALID_AMOUNT (u101)
ERR_ESCROW_NOT_FOUND (u102)
...
```

### Data Structures

#### EscrowDetails Map

```clarity
{
  seller: principal,
  buyer: principal,
  arbitrator: (optional principal),
  amount: uint,
  state: (string-ascii 20),
  created-at: uint,
  timeout: uint,
  dispute-reason: (optional (string-utf8 500))
}
```

#### ArbitratorRegistry Map

```clarity
{
  active: bool,
  cases-handled: uint,
  rating: uint
}
```

## Usage

### Creating an Escrow

```clarity
(contract-call? .bitcoin-escrow create-escrow
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; buyer
  u1000000                                      ;; amount (1 STX)
  u1440                                         ;; timeout (10 days)
)
```

### Releasing Funds

```clarity
(contract-call? .bitcoin-escrow release-funds u1)  ;; escrow-id
```

### Raising a Dispute

```clarity
(contract-call? .bitcoin-escrow raise-dispute
  u1                                              ;; escrow-id
  u"Item not as described"                        ;; reason
)
```

## Error Codes

| Code | Description             |
| ---- | ----------------------- |
| u100 | Not authorized          |
| u101 | Invalid amount          |
| u102 | Escrow not found        |
| u103 | Already exists          |
| u104 | Invalid state           |
| u105 | Insufficient funds      |
| u106 | Unauthorized arbitrator |
| u107 | Timeout not reached     |
| u108 | Invalid buyer           |
| u109 | Invalid arbitrator      |

## Getting Started

1. Deploy the contract to your Stacks network
2. Register arbitrators (contract owner only)
3. Set arbitrator fee (contract owner only)
4. Create escrow transactions
5. Manage disputes through the arbitration system

## Testing

Comprehensive test cases are available in the test suite. Run tests using Clarinet:

```bash
clarinet test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Security

Please review our [Security Policy](SECURITY.md) for reporting vulnerabilities.

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before participating in our community.

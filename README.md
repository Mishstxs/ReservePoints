# ReservePoints

A decentralized hotel booking and loyalty rewards system built on Stacks blockchain using Clarity smart contracts with **multi-cryptocurrency payment support**.

## Overview

ReservePoints enables hotels to register their properties and guests to make bookings while earning loyalty points. The system features a tiered loyalty program that rewards frequent guests with increasing benefits and now supports multiple cryptocurrencies for payments.

## Features

- **Hotel Registration**: Hotels can register and manage their properties with accepted payment currencies
- **Multi-Currency Payments**: Support for STX, Bitcoin, USDC, and USDT payments
- **Secure Bookings**: Guests can create and manage hotel reservations in their preferred currency
- **Loyalty Rewards**: Automatic points calculation based on booking value (calculated in STX equivalent)
- **Tiered System**: Bronze, Silver, Gold, and Platinum loyalty tiers
- **Booking Management**: Cancel bookings with automatic refund processing
- **Currency Exchange**: Real-time currency conversion for pricing display
- **Payment Processing**: Integrated payment handling with status tracking

## Supported Cryptocurrencies

- **STX** (Stacks) - Native blockchain currency
- **BTC** (Bitcoin) - Via wrapped Bitcoin or Lightning Network
- **USDC** (USD Coin) - Stablecoin for price stability
- **USDT** (Tether) - Alternative stablecoin option

## Smart Contract Functions

### Public Functions

#### Hotel Management
- `register-hotel(name, location, price-per-night, accepted-currencies)` - Register a new hotel with accepted payment methods
- `update-hotel(hotel-id, name, location, price-per-night, accepted-currencies)` - Update hotel details and accepted currencies
- `toggle-hotel-status(hotel-id)` - Activate/deactivate hotel

#### Booking Management
- `create-booking(hotel-id, check-in, check-out, currency)` - Create a booking reservation in specified currency
- `process-payment(booking-id)` - Process payment for a confirmed booking
- `cancel-booking(booking-id)` - Cancel an existing booking with automatic refund

#### Currency Management (Owner Only)
- `set-exchange-rate(currency, rate-to-stx)` - Set exchange rates for currency conversion
- `set-token-contract(currency, contract)` - Set token contract addresses for each supported currency

### Read-Only Functions

#### Data Retrieval
- `get-hotel(hotel-id)` - Retrieve hotel information including accepted currencies
- `get-booking(booking-id)` - Retrieve booking details including payment status
- `get-guest-loyalty(guest)` - Get guest loyalty information
- `get-counters()` - Get current booking and hotel counters

#### Currency & Pricing
- `get-exchange-rate(currency)` - Get current exchange rate for a currency
- `get-supported-currencies()` - List all supported payment currencies
- `calculate-booking-cost(hotel-id, nights, currency)` - Calculate booking cost in specific currency
- `get-tier-benefits(tier)` - Get benefits for loyalty tier

## Loyalty Tiers

- **Bronze**: 5% discount, 10% bonus points (Default tier)
- **Silver**: 10% discount, 20% bonus points (2,000+ points)
- **Gold**: 15% discount, 30% bonus points (5,000+ points)
- **Platinum**: 20% discount, 50% bonus points (10,000+ points)

*Note: Loyalty points are calculated based on STX equivalent value regardless of payment currency*

## Payment Flow

1. **Browse Hotels**: View available hotels and their accepted payment methods
2. **Select Currency**: Choose preferred payment currency from hotel's accepted list
3. **Create Booking**: Reserve dates with automatic cost calculation in chosen currency
4. **Process Payment**: Complete payment using selected cryptocurrency
5. **Earn Points**: Automatically receive loyalty points based on booking value
6. **Manage Booking**: Cancel if needed with automatic refund processing

## Currency Exchange

The system maintains exchange rates for all supported currencies relative to STX:
- Rates are updated by contract administrators
- Booking costs are calculated in real-time based on current rates
- Loyalty points are awarded based on STX equivalent value
- Refunds are processed in the original payment currency

## Installation

1. Clone the repository
```bash
git clone https://github.com/your-repo/reservepoints.git
cd reservepoints
```

2. Install Clarinet
```bash
curl -L https://github.com/hirosystems/clarinet/releases/download/v1.0.0/clarinet-linux-x64.tar.gz | tar xz
```

3. Run tests
```bash
clarinet test
```

4. Check contract
```bash
clarinet check
```

## Usage

### For Hotels
1. Register your hotel with accepted payment currencies
2. Set competitive pricing in STX (automatically converted for guests)
3. Manage bookings and receive payments in your preferred currencies
4. Update accepted payment methods as needed

### For Guests
1. Browse hotels and view pricing in your preferred currency
2. Create bookings using any supported cryptocurrency
3. Process payments securely through the smart contract
4. Earn loyalty points and climb the tier system
5. Enjoy tier-based discounts and bonus points

## Development

Built with Clarity smart contracts following Stacks best practices for:
- Security and gas optimization
- Multi-currency payment processing
- Real-time exchange rate management
- Automatic refund mechanisms
- Comprehensive error handling

## Security Features

- Owner-only functions for exchange rate management
- Guest authorization checks for all booking operations
- Input validation for all currencies and amounts
- Secure payment processing with status tracking
- Protected refund mechanisms

## Future Enhancements

- Integration with additional cryptocurrencies
- Dynamic pricing based on demand
- Multi-signature wallet support for large transactions
- Integration with DEX protocols for automatic currency conversion
- Mobile app with QR code payment processing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

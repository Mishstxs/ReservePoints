# ReservePoints

A decentralized hotel booking and loyalty rewards system built on Stacks blockchain using Clarity smart contracts with **multi-cryptocurrency payment support** and **NFT-based digital room keys**.

## Overview

ReservePoints enables hotels to register their properties and guests to make bookings while earning loyalty points. The system features a tiered loyalty program that rewards frequent guests with increasing benefits, supports multiple cryptocurrencies for payments, and issues NFT-based digital room keys for seamless check-in experiences.

## Features

- **Hotel Registration**: Hotels can register and manage their properties with accepted payment currencies
- **Multi-Currency Payments**: Support for STX, Bitcoin, USDC, and USDT payments
- **Secure Bookings**: Guests can create and manage hotel reservations in their preferred currency
- **NFT Room Keys**: Automatic issuance of digital room key NFTs upon booking confirmation
- **Digital Check-in**: Guests can use their NFT room keys for contactless check-in
- **Loyalty Rewards**: Automatic points calculation based on booking value (calculated in STX equivalent)
- **Tiered System**: Bronze, Silver, Gold, and Platinum loyalty tiers
- **Booking Management**: Cancel bookings with automatic refund processing and NFT key burning
- **Currency Exchange**: Real-time currency conversion for pricing display
- **Payment Processing**: Integrated payment handling with status tracking

## Supported Cryptocurrencies

- **STX** (Stacks) - Native blockchain currency
- **BTC** (Bitcoin) - Via wrapped Bitcoin or Lightning Network
- **USDC** (USD Coin) - Stablecoin for price stability
- **USDT** (Tether) - Alternative stablecoin option

## NFT Room Keys

### Features
- **Automatic Issuance**: NFT room keys are automatically minted when bookings are confirmed and payments processed
- **Unique Metadata**: Each key contains booking details, room information, and validity period
- **Access Control**: Keys are only valid during the guest's stay period (check-in to check-out + 1 day buffer)
- **Secure Transfer**: Keys can be transferred to other principals if needed
- **Automatic Cleanup**: Keys are burned when bookings are cancelled or expired

### Key Metadata
- Room number and hotel information
- Guest principal and booking ID
- Validity period (check-in to check-out dates)
- Access permissions and special instructions
- Unique tokenized representation of booking

## Smart Contract Functions

### Public Functions

#### Hotel Management
- `register-hotel(name, location, price-per-night, accepted-currencies)` - Register a new hotel with accepted payment methods
- `update-hotel(hotel-id, name, location, price-per-night, accepted-currencies)` - Update hotel details and accepted currencies
- `toggle-hotel-status(hotel-id)` - Activate/deactivate hotel

#### Booking Management
- `create-booking(hotel-id, check-in, check-out, currency)` - Create a booking reservation in specified currency
- `process-payment(booking-id)` - Process payment and mint NFT room key for confirmed booking
- `cancel-booking(booking-id)` - Cancel booking with automatic refund and NFT key burning

#### NFT Room Key Management
- `mint-room-key(booking-id, room-number, metadata-uri)` - Mint NFT room key for confirmed booking (hotel owner only)
- `burn-room-key(token-id)` - Burn expired or cancelled room key NFT
- `transfer-room-key(token-id, recipient)` - Transfer room key to another principal (guest or delegate)

#### Currency Management (Owner Only)
- `set-exchange-rate(currency, rate-to-stx)` - Set exchange rates for currency conversion
- `set-token-contract(currency, contract)` - Set token contract addresses for each supported currency

### Read-Only Functions

#### Data Retrieval
- `get-hotel(hotel-id)` - Retrieve hotel information including accepted currencies
- `get-booking(booking-id)` - Retrieve booking details including payment status and room key info
- `get-guest-loyalty(guest)` - Get guest loyalty information
- `get-counters()` - Get current booking and hotel counters

#### NFT Room Key Functions
- `get-room-key(token-id)` - Retrieve room key NFT details and metadata
- `get-room-key-by-booking(booking-id)` - Get room key associated with a booking
- `get-room-keys-by-guest(guest)` - List all active room keys for a guest
- `is-room-key-valid(token-id)` - Check if room key is valid for current date
- `get-token-uri(token-id)` - Get NFT metadata URI for room key

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

## Payment and Check-in Flow

1. **Browse Hotels**: View available hotels and their accepted payment methods
2. **Select Currency**: Choose preferred payment currency from hotel's accepted list
3. **Create Booking**: Reserve dates with automatic cost calculation in chosen currency
4. **Process Payment**: Complete payment using selected cryptocurrency
5. **Receive NFT Key**: Automatically receive digital room key NFT upon payment confirmation
6. **Digital Check-in**: Use NFT room key for contactless hotel check-in
7. **Earn Points**: Automatically receive loyalty points based on booking value
8. **Manage Booking**: Cancel if needed with automatic refund processing and key burning

## NFT Room Key Benefits

### For Guests
- **Contactless Check-in**: No need for physical key cards or front desk interaction
- **Secure Access**: Blockchain-verified room access credentials
- **Transferable**: Can delegate access to family members or colleagues
- **Proof of Stay**: Permanent record of hotel visits on blockchain
- **Mobile Friendly**: Access keys through any Stacks-compatible wallet

### For Hotels
- **Reduced Operations**: Automated key management and check-in process
- **Enhanced Security**: Cryptographic room access control
- **Guest Analytics**: Detailed insights into guest behavior and preferences
- **Cost Savings**: Reduced physical key card production and management
- **Brand Innovation**: Cutting-edge technology enhances guest experience

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
4. Issue NFT room keys automatically upon booking confirmation
5. Update accepted payment methods as needed

### For Guests
1. Browse hotels and view pricing in your preferred currency
2. Create bookings using any supported cryptocurrency
3. Process payments securely through the smart contract
4. Receive NFT-based digital room keys automatically
5. Use room keys for contactless check-in
6. Earn loyalty points and climb the tier system
7. Enjoy tier-based discounts and bonus points

## Development

Built with Clarity smart contracts following Stacks best practices for:
- Security and gas optimization
- Multi-currency payment processing
- NFT standard compliance (SIP-009)
- Real-time exchange rate management
- Automatic refund mechanisms
- Comprehensive error handling

## Security Features

- Owner-only functions for exchange rate management
- Guest authorization checks for all booking operations
- Input validation for all currencies and amounts
- Secure payment processing with status tracking
- Protected refund mechanisms
- NFT access control and validation
- Automatic key expiration and cleanup

## Future Enhancements

- Integration with additional cryptocurrencies
- Dynamic pricing based on demand
- Multi-signature wallet support for large transactions
- Integration with DEX protocols for automatic currency conversion
- Mobile app with QR code payment processing
- IoT integration for smart room access
- Advanced NFT metadata with room photos and amenities
- Integration with hotel management systems

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request
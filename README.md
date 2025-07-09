# ReservePoints

A decentralized hotel booking and loyalty rewards system built on Stacks blockchain using Clarity smart contracts.

## Overview

ReservePoints enables hotels to register their properties and guests to make bookings while earning loyalty points. The system features a tiered loyalty program that rewards frequent guests with increasing benefits.

## Features

- **Hotel Registration**: Hotels can register and manage their properties
- **Secure Bookings**: Guests can create and manage hotel reservations
- **Loyalty Rewards**: Automatic points calculation based on booking value
- **Tiered System**: Bronze, Silver, Gold, and Platinum loyalty tiers
- **Booking Management**: Cancel bookings with proper status tracking

## Smart Contract Functions

### Public Functions

- `register-hotel(name, location, price-per-night)` - Register a new hotel
- `create-booking(hotel-id, check-in, check-out)` - Create a booking reservation
- `cancel-booking(booking-id)` - Cancel an existing booking
- `update-hotel(hotel-id, name, location, price-per-night)` - Update hotel details
- `toggle-hotel-status(hotel-id)` - Activate/deactivate hotel

### Read-Only Functions

- `get-hotel(hotel-id)` - Retrieve hotel information
- `get-booking(booking-id)` - Retrieve booking details
- `get-guest-loyalty(guest)` - Get guest loyalty information
- `get-counters()` - Get current booking and hotel counters
- `get-tier-benefits(tier)` - Get benefits for loyalty tier

## Loyalty Tiers

- **Bronze**: 5% discount, 10% bonus points
- **Silver**: 10% discount, 20% bonus points (2,000+ points)
- **Gold**: 15% discount, 30% bonus points (5,000+ points)
- **Platinum**: 20% discount, 50% bonus points (10,000+ points)

## Installation

1. Clone the repository
2. Install Clarinet: `curl -L https://github.com/hirosystems/clarinet/releases/download/v1.0.0/clarinet-linux-x64.tar.gz | tar xz`
3. Run tests: `clarinet test`
4. Check contract: `clarinet check`

## Usage

Deploy the contract to Stacks testnet and interact with it using the provided functions. Hotels can register their properties, and guests can make bookings to earn loyalty points.

## Development

Built with Clarity smart contracts following Stacks best practices for security and gas optimization.


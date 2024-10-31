# NFT Collateralized lending protocol

This protocol uses a Peer-to-Protocol architecture

![Screenshot from 2024-10-30 01-06-32](https://github.com/user-attachments/assets/1efe8e0e-cf0d-40db-a496-e4116ee66561)

## Flowchart
![flow drawio](https://github.com/user-attachments/assets/e68a8ca3-ebd9-42de-9c67-b68d6183767f)

## Installation

- Clone this repo
- Install dependencies

```bash
$ yarn && forge update
```

### Compile

```bash
$ npx hardhat compile
```

## Deployment

### Hardhat

```bash
$ npx hardhat run scripts/deploy.js
```

### Foundry

```bash
$ forge t
```

`Note`: A lot of improvements are still needed so contributions are welcome!!

Bonus: The [DiamondLoupefacet](contracts/facets/DiamondLoupeFacet.sol) uses an updated [LibDiamond](contracts/libraries//LibDiamond.sol) which utilises solidity custom errors to make debugging easier especially when upgrading diamonds. Take it for a spin!!

Need some more clarity? message me [on twitter](https://twitter.com/Timidan_x), Or join the [EIP-2535 Diamonds Discord server](https://discord.gg/kQewPw2)

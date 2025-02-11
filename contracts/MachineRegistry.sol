// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact security@nidum.ai
contract MachineRegistry is Ownable {
    struct Machine {
        string os;
        string cpu;
        string ram;
        string connectionSpeed;
        uint256 startedAt;
        uint256 endedAt;
        string paid;
        bool isAlive;
    }

    mapping(address => string[]) private apps;
    mapping(string => Machine) private appToMachine;
    mapping(address => bool) private owners;
    mapping(string => bool) private registeredApps;

    event MachineAdded(address indexed owner, string appId);
    event MachineUpdated(string indexed appId);
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed owner);

    // Constructor to set initial owner
    constructor() Ownable(msg.sender) {
        owners[msg.sender] = true;
    }

    modifier onlyOwners() {
        require(owners[msg.sender], "Caller is not an owner");
        _;
    }

    // Function to add a new owner
    function addOwner(address newOwner) external onlyOwners {
        owners[newOwner] = true;
        emit OwnerAdded(newOwner);
    }

    // Function to remove an owner
    function removeOwner(address _owner) external onlyOwners {
        require(_owner != msg.sender, "You cannot remove yourself");
        require(owners[_owner], "Address is not an owner");

        owners[_owner] = false;
        emit OwnerRemoved(_owner);
    }

    // Function to add a new machine entry
    function addMachine(
        string memory appId,
        string memory _os,
        string memory _cpu,
        string memory _ram,
        string memory _connectionSpeed,
        string memory _paid
    ) external {
        require(
            !registeredApps[appId],
            "Machine with this appId already exists"
        );

        registeredApps[appId] = true;
        apps[msg.sender].push(appId);
        appToMachine[appId] = Machine(
            _os,
            _cpu,
            _ram,
            _connectionSpeed,
            block.timestamp,
            0,
            _paid,
            true
        );

        emit MachineAdded(msg.sender, appId);
    }

    // Function to end a connection by updating the endedAt timestamp
    function endConnection(string memory appId) external {
        require(
            appToMachine[appId].isAlive,
            "Machine is already inactive or does not exist"
        );
        require(registeredApps[appId], "Machine does not exist");

        // Ensure only the creator can end their machine session
        bool _isOwner = false;
        for (uint256 i = 0; i < apps[msg.sender].length; i++) {
            if (
                keccak256(bytes(apps[msg.sender][i])) == keccak256(bytes(appId))
            ) {
                _isOwner = true;
                break;
            }
        }
        require(_isOwner, "Not authorized");

        appToMachine[appId].endedAt = block.timestamp;
        appToMachine[appId].isAlive = false;

        emit MachineUpdated(appId);
    }

    // Function to update paid status and isAlive state
    function updateMachine(
        string memory appId,
        string memory _paid,
        bool _isAlive
    ) external {
        require(
            bytes(appToMachine[appId].os).length > 0,
            "Machine does not exist"
        );

        appToMachine[appId].paid = _paid;
        appToMachine[appId].isAlive = _isAlive;

        emit MachineUpdated(appId);
    }

    // Function to fetch all apps of an address (only owners can call)
    function getAppsByAddress(
        address owner
    ) external view onlyOwners returns (string[] memory) {
        return apps[owner];
    }

    // Function to fetch my apps
    function getMyApps() external view returns (string[] memory) {
        return apps[msg.sender];
    }

    // Function to fetch all machines that are still alive
    function getAliveMachines() external view returns (Machine[] memory) {
        string[] memory userApps = apps[msg.sender];
        uint256 totalAlive = 0;

        // First loop: count alive machines
        for (uint256 i = 0; i < userApps.length; i++) {
            if (appToMachine[userApps[i]].isAlive) {
                totalAlive++;
            }
        }

        // Second loop: store them
        Machine[] memory aliveMachines = new Machine[](totalAlive);
        uint256 index = 0;
        for (uint256 i = 0; i < userApps.length; i++) {
            if (appToMachine[userApps[i]].isAlive) {
                aliveMachines[index++] = appToMachine[userApps[i]];
            }
        }

        return aliveMachines;
    }

    // Function to check if an appId exists and fetch machine data
    function getMachineByAppId(
        string memory appId
    ) external view returns (Machine memory) {
        require(
            bytes(appToMachine[appId].os).length > 0,
            "Machine does not exist"
        );
        return appToMachine[appId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;


contract ColourBottle {
    struct GameStatus {
        uint256[5] correctArrangement; 
        uint256 attempts;              
        bool isActive;                 
        bool hasWon;              
    }
    
    mapping(address => GameStatus) public games;
    
    // Events
    event GameStarted(address player, uint256 timestamp);
    event AttemptMade(address player, uint256 correctPositions);
    event GameWon(address player, uint256 attempts);
    event GameReset(address player);
    
    // Errors
    error NoActiveGame(address player);
    error GameAlreadyWon(address player);
    error MaxAttemptsReached(address player);
    error InvalidBottleNumber(uint256 bottleNumber);
    error GameStillInProgress(address player);
    error InvalidInput(address player, uint256 attemptIndex, uint256 bottleNumber);
        
    function startNewGame() public {
        if (games[msg.sender].isActive) {
            revert GameStillInProgress(msg.sender);
        }
        
        if (games[msg.sender].hasWon || games[msg.sender].attempts >= 5) {
            uint256[5] memory newArrangement = generateRandomArrangement();
        
            games[msg.sender] = GameStatus({
                correctArrangement: newArrangement,
                attempts: 0,
                isActive: true,
                hasWon: false
            });
        
            emit GameStarted(msg.sender, block.timestamp);
        }
    }
    
    function makeAttempt(uint256[5] memory attempt) public returns (uint256) {
        GameStatus storage game = games[msg.sender];
        
        if (!game.isActive) {
            revert NoActiveGame(msg.sender);
        }
        
        if (game.hasWon) {
            revert GameAlreadyWon(msg.sender);
        }

        if (game.attempts >= 5) {
            revert MaxAttemptsReached(msg.sender);
        }
        
        for (uint256 i = 0; i < 5; i++) {
            uint256 bottleNumber = attempt[i];
            if (bottleNumber < 1 || bottleNumber > 5) {
                revert InvalidBottleNumber(bottleNumber);
            }
            
            if (bottleNumber > 5) {
                revert InvalidInput(msg.sender, i, bottleNumber);
            }
        }
        
        uint256 correctPositions = 0;
        for (uint256 i = 0; i < 5; i++) {
            if (attempt[i] == game.correctArrangement[i]) {
                correctPositions++;
            }
        }
        
        game.attempts++;
        
        if (correctPositions == 5) {
            game.hasWon = true;
            emit GameWon(msg.sender, game.attempts);
        } else if (game.attempts >= 5) {
            game.isActive = false;
            emit GameReset(msg.sender); 
        }
        
        emit AttemptMade(msg.sender, correctPositions);
        
        return correctPositions;
    }
    
   
    function generateRandomArrangement() internal view returns (uint256[5] memory) {
        uint256[5] memory arrangement;
        uint256[5] memory used = [uint256(0), 0, 0, 0, 0];
        
        for (uint256 i = 0; i < 5; i++) {
            uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % 5;
            uint256 value = 0;
            uint256 count = 0;
            
            for (uint256 j = 1; j <= 5; j++) {
                if (used[j - 1] == 0) {
                    if (count == rand) {
                        value = j;
                        break;
                    }
                    count++;
                }
            }
            
            arrangement[i] = value;
            used[value - 1] = 1;
        }
        
        return arrangement;
    }
    
    function getGameStatus() public view returns (
        uint256 attempts,
        bool isActive,
        bool hasWon
    ) {
        GameStatus storage game = games[msg.sender];
        return (game.attempts, game.isActive, game.hasWon);
    }
    
    function getRemainingAttempts() public view returns (uint256) {
        return 5 - games[msg.sender].attempts;
    }
}

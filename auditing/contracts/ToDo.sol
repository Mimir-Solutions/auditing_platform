// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

import "./Auditable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract ToDo is Auditable {

    using SafeMath for uint256;

    modifier taskExists( uint256 taskID ) {
        require( 0 < tasks[ _msgSender() ].length,        "Task list is empty" );
        require( taskID <= tasks[ _msgSender() ].length,  "Task does not exist" );
        _;
    }

    struct Task {
        uint256 priority;
        bool completed;
        string task;
    }

    // keep your naughtiness to yourself
    mapping( address => Task[] ) private tasks;

    event AddedTask(            address creator, uint256 taskID);
    event CompletedTask(        address creator, uint256 taskID);
    event RevertedTask(         address creator, uint256 taskID);
    event UpdatedDescription(   address creator, uint256 taskID);
    event UpdatedPriority(      address creator, uint256 taskID);

    constructor( address auditor, address platform ) Auditable( auditor, platform ) public {}

    function safeTaskID( uint256 taskID ) private pure returns ( uint256 ) {
        // Cannot completely tailer to everyone because I can either start from the 0th indexed
        // so the user must know to start counting from 0 or alternatively start from 1
        // Tailor to majority starting at 1 by decrementing the number
        if ( taskID != 0 ) {
            taskID = taskID.sub( 1 );
        }
        return taskID;
    }

    function viewTask( uint256 taskID ) external isApproved() taskExists( taskID ) view returns ( uint256, bool, string memory ) {
        taskID = safeTaskID( taskID );
        return 
        (
            tasks[ _msgSender() ][ taskID ].priority,
            tasks[ _msgSender() ][ taskID ].completed, 
            tasks[ _msgSender() ][ taskID ].task
        );
    }

    function addTask( string calldata task ) external isApproved() {
        tasks[ _msgSender() ].push( Task({
            priority: tasks[ _msgSender() ].length + 1,
            completed: false, 
            task: task
        }));

        emit AddedTask( _msgSender(), tasks[_msgSender()].length );
    }
    
    function changeTaskPriority( uint256 taskID, uint256 priority ) external isApproved() taskExists( taskID ) {
        uint256 id = taskID;
        taskID = safeTaskID( taskID );
        
        require( !tasks[ _msgSender() ][ taskID ].completed,            "Cannot edit completed task" );
        require( tasks[ _msgSender() ][ taskID ].priority != priority,  "New priority must be different" );
        
        tasks[ _msgSender() ][ taskID ].priority = priority;

        emit UpdatedPriority( _msgSender(), id );
    }
    
    function changeTaskDescription( uint256 taskID, string calldata task ) external isApproved() taskExists( taskID ) {
        uint256 id = taskID;
        taskID = safeTaskID( taskID );
        
        require(!tasks[ _msgSender() ][ taskID ].completed, "Cannot edit completed task");
        require( keccak256( abi.encodePacked( tasks[ _msgSender() ][ taskID ].task ) ) != keccak256( abi.encodePacked( task ) ), "New description must be different" );
        
        tasks[ _msgSender() ][ taskID ].task = task;

        emit UpdatedDescription( _msgSender(), id );
    }
    
    function completeTask( uint256 taskID ) external isApproved() taskExists( taskID ) {
        uint256 id = taskID;
        taskID = safeTaskID( taskID );
        
        require( !tasks[ _msgSender() ][ taskID ].completed, "Task has already been completed" );
        
        tasks[ _msgSender() ][ taskID ].completed = true;

        emit CompletedTask( _msgSender(), id );
    }

    function undoTask( uint256 taskID ) external isApproved() taskExists( taskID ) {
        uint256 id = taskID;
        taskID = safeTaskID( taskID );
        
        require( tasks[ _msgSender() ][ taskID ].completed, "Task has not been completed" );

        tasks[ _msgSender() ][ taskID ].completed = false;

        emit RevertedTask( _msgSender(), id );
    }
    
    function taskCount() external isApproved() view returns ( uint256 ) {
        return tasks[ _msgSender() ].length;
    }
    
    function completedTaskCount() external isApproved() view returns ( uint256 ) {
        // loops are evil. if you add too many tasks then RIP you
        uint256 completed;
        
        for ( uint256 ID; ID < tasks[_msgSender()].length; ID++) {
            if ( tasks[ _msgSender() ][ ID ].completed ) {
                completed = completed.add( 1 );
            }
        }
        
        return completed;
    }
    
    function incompleteTaskCount() external isApproved() view returns ( uint256 ) {
        // loops are evil. if you add too many tasks then RIP you
        uint256 incomplete;
        
        for (uint256 ID; ID < tasks[_msgSender()].length; ID++) {
            if ( !tasks[ _msgSender() ][ ID ].completed ) {
                incomplete = incomplete.add(1);
            }
        }
        
        return incomplete;
    }

    function taskPriority( uint256 taskID ) external isApproved() taskExists( taskID ) view returns ( uint256 ) {
        return tasks[ _msgSender() ][ safeTaskID( taskID ) ].priority;
    }

    function isTaskCompleted(uint256 taskID) external isApproved() taskExists( taskID ) view returns ( bool ) {
        return tasks[ _msgSender() ][ safeTaskID( taskID ) ].completed;
    }
    
    function taskDescription( uint256 taskID ) external isApproved() taskExists( taskID ) view returns ( string memory ) {
        return tasks[ _msgSender() ][ safeTaskID( taskID ) ].task;
    }
}
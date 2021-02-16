// SPDX-License-Identifier: AGPL v3
pragma solidity ^0.8.1;

import "./SafeMath.sol";
import "./Auditable.sol";

contract ToDo is Auditable {

    using SafeMath for uint256;

    // There must be at least one task in their list and the taskID must be at most the index of the last task
    modifier taskExists( uint256 taskID ) {
        require( 0 < tasks[ _msgSender() ].length,        "Task list is empty" );
        require( taskID <= tasks[ _msgSender() ].length,  "Task does not exist" );
        _;
    }

    // Keep track of the description, status and priority
    struct Task {
        uint256 priority;
        bool completed;
        string description;
    }

    // Your private tasks are your own, stop shoulder surfing
    mapping( address => Task[] ) private tasks;
    mapping( address => uint256 ) private tasksCompleted;

    event AddedTask(            address creator, uint256 taskID);
    event CompletedTask(        address creator, uint256 taskID);
    event RevertedTask(         address creator, uint256 taskID);
    event UpdatedDescription(   address creator, uint256 taskID);
    event UpdatedPriority(      address creator, uint256 taskID);

    constructor() Auditable() public {}

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
            tasks[ msg.sender ][ taskID ].priority,
            tasks[ msg.sender ][ taskID ].completed, 
            tasks[ msg.sender ][ taskID ].description
        );
    }

    function addTask( string calldata description ) external isApproved() {
        // Nothing fancy in terms of priority. They can update it with another function instead of overloading or having an additional parameter
        tasks[ msg.sender ].push( Task({
            priority: tasks[ msg.sender ].length + 1,
            completed: false, 
            description: description
        }));

        emit AddedTask( msg.sender, tasks[ msg.sender ].length );
    }
    
    function changeTaskPriority( uint256 taskID, uint256 priority ) external isApproved() taskExists( taskID ) {
        uint256 id = taskID;
        taskID = safeTaskID( taskID );
        
        require( !tasks[ msg.sender ][ taskID ].completed,            "Cannot edit completed task" );
        require( tasks[ msg.sender ][ taskID ].priority != priority,  "New priority must be different" ); // Keep your money, fool. You need it
        
        tasks[ msg.sender ][ taskID ].priority = priority;

        emit UpdatedPriority( msg.sender, id );
    }
    
    function changeTaskDescription( uint256 taskID, string calldata description ) external isApproved() taskExists( taskID ) {
        uint256 id = taskID;
        taskID = safeTaskID( taskID );
        
        require( !tasks[ msg.sender ][ taskID ].completed, "Cannot edit completed task" );
        require( keccak256( abi.encodePacked( tasks[ msg.sender ][ taskID ].description ) ) != keccak256( abi.encodePacked( description ) ), "New description must be different" ); // Keep your money, fool. You need it
        
        tasks[ msg.sender ][ taskID ].description = description;

        emit UpdatedDescription( msg.sender, id );
    }
    
    function completeTask( uint256 taskID ) external isApproved() taskExists( taskID ) {
        uint256 id = taskID;
        taskID = safeTaskID( taskID );
        
        require( !tasks[ msg.sender ][ taskID ].completed, "Task has already been completed" );
        
        tasks[ msg.sender ][ taskID ].completed = true;
        tasksCompleted[ msg.sender ].add( 1 );

        emit CompletedTask( msg.sender, id );
    }

    function undoTask( uint256 taskID ) external isApproved() taskExists( taskID ) {
        uint256 id = taskID;
        taskID = safeTaskID( taskID );
        
        require( tasks[ msg.sender ][ taskID ].completed, "Task has not been completed" );

        tasks[ msg.sender ][ taskID ].completed = false;
        tasksCompleted[ msg.sender ].sub( 1 );

        emit RevertedTask( msg.sender, id );
    }
    
    function taskCount() external isApproved() view returns ( uint256 ) {
        return tasks[ msg.sender ].length;
    }
    
    function completedTaskCount() external isApproved() view returns ( uint256 ) {
        return tasksCompleted[ msg.sender ];
    }
    
    function incompleteTaskCount() external isApproved() view returns ( uint256 ) {
        return tasks[ msg.sender ].length - tasksCompleted[ msg.sender ];
    }

    function taskPriority( uint256 taskID ) external isApproved() taskExists( taskID ) view returns ( uint256 ) {
        return tasks[ msg.sender ][ safeTaskID( taskID ) ].priority;
    }

    function isTaskCompleted(uint256 taskID) external isApproved() taskExists( taskID ) view returns ( bool ) {
        return tasks[ msg.sender ][ safeTaskID( taskID ) ].completed;
    }
    
    function taskDescription( uint256 taskID ) external isApproved() taskExists( taskID ) view returns ( string memory ) {
        return tasks[ msg.sender ][ safeTaskID( taskID ) ].description;
    }
}




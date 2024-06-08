// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address  USER = makeAddr("user");
    uint256 constant SEND_VALUE=0.1 ether;
    uint256 constant STARTINGBALANCE=10 ether;
    function setUp() external {
        // fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTINGBALANCE);
    }

    function testMindollarisfive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwner() public {
        console.log(fundMe.i_owner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // Given that the test is passing when using address(this) instead of msg.sender, it indicates that i_owner is set to the address of the contract (address(this)) rather than the address that sent the transaction (msg.sender). This behavior is expected if i_owner is initialized in the contract constructor to be the address of the contract itself.

    function testFeedPriceVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFail() {
        vm.expectRevert();
        fundMe.fund();
    }
    function testFundUpdate()public {
        vm.prank (USER)
        fundMe.fund(value:SEND_VALUE)();
        uint256 amountFunded = fundMe.getAddressToAmount(USER);
        assertEq(amount ,SEND_VALUE);
    }
    function AddFunderToArray () public {
        vm.prank(USER);
        fundMe.fund(value:SEND_VALUE());
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
    modifier funded(){
        vm.prank(USER);
        fundMe.fund(value: SEND_VALUE);
        _;
    }
    function testonlyOwnerWithdraw()public funded{
        vm.prank (USER)
        vm.expectRevert();
        fundMe.withdraw();
    }
    function testWithdraw() public funded{
        uint256 startownerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance= address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance= address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingFundMeBalance + startownerBalance, endingFundMeBalance);

    }
    function testWithdrawmultiplefunders() public funded{
        uint160 noOffunders=10;
        uint160 startingFunderIndex=2;
        for(uint256 i= startingFunderIndex; i<noOffunders; i++ ){
            hoax(address(i), SEND_VALUE);
            fundMe.fund(value:SEND_VALUE);

        }
        uint256 startownerBalance=fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance==0);
        assert(startingFundMeBalance+startownerBalance==fundMe.getOwner().balance);
        
    }
}

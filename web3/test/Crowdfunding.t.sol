// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../contracts/Crowdfunding.sol";

// A contract that cannot receive ETH, used to test failed transfers
contract Rejector {}

contract CrowdfundingTest is Test {
    Crowdfunding crowdfunding;
    address owner = address(0x1);
    address donor = address(0x2);

    function setUp() public {
        crowdfunding = new Crowdfunding();
        vm.deal(donor, 10 ether);
    }

    function _create() internal returns (uint256) {
        vm.prank(owner);
        return crowdfunding.createCampaign(
            owner, "Title", "Desc", 5 ether, block.timestamp + 1 days, "img"
        );
    }

    function testCreateCampaign() public {
        uint256 id = _create();
        assertEq(id, 0);
        assertEq(crowdfunding.numberOfCampaigns(), 1);
        (address o, , , , , , ) = crowdfunding.campaigns(id);
        assertEq(o, owner);
    }

    function testCreateRevertsOnPastDeadline() public {
        vm.expectRevert("The deadline should be a date in the future.");
        vm.prank(owner);
        crowdfunding.createCampaign(owner, "T", "D", 1 ether, block.timestamp, "img");
    }

    function testCreateRevertsIfOwnerIsNotCaller() public {
        vm.expectRevert("Owner must be the caller.");
        vm.prank(donor);
        crowdfunding.createCampaign(owner, "T", "D", 1 ether, block.timestamp + 1 days, "img");
    }

    function testDonationReachesOwner() public {
        uint256 id = _create();
        vm.prank(donor);
        crowdfunding.donateToCampaign{value: 1 ether}(id);
        assertEq(owner.balance, 1 ether);
        (, , , , , uint256 collected, ) = crowdfunding.campaigns(id);
        assertEq(collected, 1 ether);
    }

    function testDonateRevertsAfterDeadline() public {
        uint256 id = _create();
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert("Campaign has ended.");
        vm.prank(donor);
        crowdfunding.donateToCampaign{value: 1 ether}(id);
    }

    function testDonateRevertsOnZeroValue() public {
        uint256 id = _create();
        vm.expectRevert("Donation must be greater than zero.");
        vm.prank(donor);
        crowdfunding.donateToCampaign{value: 0}(id);
    }

    function testDonateRevertsIfCampaignMissing() public {
        vm.expectRevert("Campaign does not exist.");
        vm.prank(donor);
        crowdfunding.donateToCampaign{value: 1 ether}(99);
    }

    function testTransferFailureReverts() public {
        Rejector rejector = new Rejector();
        vm.prank(address(rejector));
        uint256 id = crowdfunding.createCampaign(
            address(rejector), "T", "D", 1 ether, block.timestamp + 1 days, "img"
        );
        vm.expectRevert("Failed to send ETH to the campaign owner.");
        vm.prank(donor);
        crowdfunding.donateToCampaign{value: 1 ether}(id);
    }

    function testGetDonators() public {
        uint256 id = _create();
        vm.prank(donor);
        crowdfunding.donateToCampaign{value: 1 ether}(id);
        (address[] memory donators, uint256[] memory amounts) = crowdfunding.getDonators(id);
        assertEq(donators.length, 1);
        assertEq(donators[0], donor);
        assertEq(amounts[0], 1 ether);
    }
}
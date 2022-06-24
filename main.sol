// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';


/**
 * @notice A Chainlink client that fetches and hashes ESG data from
 * the c02 labs platform.
 * @dev Testnet implementation.
 */
contract ESGConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    bytes32 private jobId;
    uint256 private fee;
    bytes32 public hashedESGData;

    event ObtainedData(bytes32 indexed requestId, bytes rawData);

    /**
     * @dev NETWORK: RINKEBY
     */
    constructor() ConfirmedOwner(msg.sender) {
        // LINK Token and Oracle address for the Rinkeby Testnet
        setChainlinkToken(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
        setChainlinkOracle(0xf3FBB7f3391F62C8fe53f89B41dFC8159EE9653f);

        // jobId with the Http -> JsonParse -> Ethabiencode tasks
        jobId = "7da2702f37fd48e5b1b9a5715e3509b6";

        // requests on testnets cost 0.1 LINK
        fee = (1 * LINK_DIVISIBILITY) / 10;
    }

    /**
     * @notice Requests ESG data from c02 endpoint
     */
    function requestESGData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        req.add("get", "https://c02-systems.ga/api/v1/show");
        req.add("path", "0,content,form,overview,project_name");

        return sendChainlinkRequest(req, fee);
    }

    /**
     * @notice Callback function to return ESG data to this contract.
     * @param _requestId bytes32
     * @param _data bytes The data returned by the oracle.
     */
    function fulfill(bytes32 _requestId, bytes memory _data) public recordChainlinkFulfillment(_requestId) {
        emit ObtainedData(_requestId, _data);
        
        hashedESGData = sha256(_data);
    }

    /**
     * @notice Allow withdraw of Link tokens from the contract.
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());

        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}

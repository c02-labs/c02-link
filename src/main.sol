// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

/**
 * @notice A Chainlink client that fetches ESG report data from
 * the c02 labs platform.
 * @dev Testnet implementation.
 */
contract ESGConsumerDemo is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    bytes32 private jobId;
    uint256 private fee;

    // ring buffer as storage
    uint8 private idx;
    string[256] public reportHashes;

    event ObtainedData(bytes32 indexed requestId, string rawData);

    /**
     * @dev NETWORK: GOERLI
     */
    constructor() ConfirmedOwner(msg.sender) {
        // LINK Token and Oracle address for the Goerli Testnet
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);

        // Testnet oracle job
        // GET>string: Http -> JsonParse -> Ethabiencode tasks
        jobId = "7d80a6386ef543a3abb52817f6707e3b";

        // requests on testnets cost 0.1 LINK
        fee = (1 * LINK_DIVISIBILITY) / 10;
    }

    /**
     * @notice Request report data for a specific client ID from c02 platform endpoint.
     */
    function requestReportHash(string memory id) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        req.add("get", string.concat("https://qaz8j911n5.execute-api.us-east-1.amazonaws.com/dev/report/", id, "/hash"));
        req.add("path", "reportHash");

        return sendChainlinkRequest(req, fee);
    }

    /**
     * @notice Callback function to return ESG report data to this contract.
     * @param _requestId bytes32
     * @param _data bytes The data returned by the oracle.
     */
    function fulfill(bytes32 _requestId, string memory _data) public recordChainlinkFulfillment(_requestId) {
        emit ObtainedData(_requestId, _data);

        reportHashes[idx] = _data;
        unchecked { idx += 1; }  // overflow me, baby
    }

    /**
     * @notice Allow withdraw of Link tokens from the contract.
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}

pragma solidity ^0.5.0; 
pragma experimental ABIEncoderV2;

import './KIP17Token.sol';

contract Jogakbo is KIP17Token('DonationMarket','DM' ){

    struct Campaign {
        address payable campaign_address; // 기부금이 모일 주소
        uint256 campaign_ID; // DB에서 받을 캠페인 아이디
       // string IPFS_url; // IPFS_url
        uint256 target_amount; // 목표 모금액
        uint256 current_amount; // 현재 모금액
        bool campaign_state;    // 캠페인 상태(모금중, 모금끝)
        bool campaign_refund_state; // 캠페인 환불 상태 (환불 불가, 환불 가능)
        bool campaign_send_state; // 모금 끝나고 기부금 전송
        mapping(address => uint256) campaign_fundingAmountList; // 캠페인에 모금한 사람과 그 funding amount List
    }

    mapping(address => uint256[]) public campaignId; // 캠페인에 고유 숫자 부여. 해당 단체가 올린 캠페인 찾을 수 있음. 
    Campaign[] public campaignList; // 구조체 Campaign을 저장하는 전체 배열 campaign_list
    mapping(uint256 => address[]) public userList;
    uint public CampaignNumber = 0;
    uint256 contractBalance = 0;
    uint256 tokenId = 0;


    // 캠페인 등록
   
    function createCampaign(
        address payable _campaign_address, uint256 _target_amount, uint256 _campaign_ID // 캠페인 생성 시 모금될 주소와 IPFS_uri와 목표 금액을 인자로 받음
    ) public {

        // 입력받은 캠페인 인스턴스 생성
        Campaign memory newCampaign = Campaign({
            campaign_address: _campaign_address,
            campaign_ID: _campaign_ID,
           // IPFS_url: _IPFS_url,
            target_amount: _target_amount,
            current_amount: 0,
            campaign_state : true,
            campaign_refund_state : false,
            campaign_send_state : false 
        });

        // 배열에 새로운 캠페인를 삽입
        campaignList.push(newCampaign);
        CampaignNumber++;
    }


    // 캠페인 존재여부 확인하는 함수
    function hasCampaign(uint256 _campaignId) private view returns (bool) { //private로 내부 함수에서만 호출 
        if (campaignList.length >= _campaignId) {
            return true;
        }
        return false;
    }

    function SendState(uint256 _campaignId) private view returns (bool) {
        return campaignList[_campaignId].campaign_send_state;
    } 

    function setStateToSend(uint256 _campaignId) private {  // 모금 끝 기부금 전송하기 위해 버튼 활성화
        campaignList[_campaignId].campaign_state = false;
        campaignList[_campaignId].campaign_send_state = true;
    }

    // 기부금 전송
    function sendDonation (uint256 _campaignId) private {
        require(campaignList[_campaignId].campaign_state == false, "아직 모금 중인 캠페인입니다.");

        //campaign_address = _campaign_address;
        uint256 donationAmount = campaignList[_campaignId].current_amount;

        campaignList[_campaignId].campaign_address.transfer(donationAmount);
    }

    // 기부
    function donateTocampaign(uint256 _campaignId, uint256 _amount) public payable {

        // 존재하는 캠페인인지 확인
        require(hasCampaign(_campaignId), "존재하지 않는 캠페인입니다.");
        // 모금이 끝난 캠페인인지 확인
        require(campaignList[_campaignId].campaign_state == true, "이 캠페인은 모금이 끝났습니다..");
        // 기부 금액이 0보다 커야함
        require(_amount > 0, "기부금액은 0보다 커야합니다.");
        // 기부 금액이 실제 할당한 금액과 같은지
        require(msg.value == _amount, "입력한 금액과 실제 기부금액이 다릅니다.");
        
        // 송금  
        contractBalance += msg.value;
      
        // 캠페인에 현재 기부금액 업데이트
        campaignList[_campaignId].current_amount += _amount;
        campaignList[_campaignId].campaign_fundingAmountList[msg.sender] += _amount;
        
        // 기부 목표 금액과 현재 모금액 확인. 모금액이 목표금액보다 크거나 같으면, 상태 변경
        if (campaignList[_campaignId].current_amount >= campaignList[_campaignId].target_amount) {
            setStateToSend(_campaignId);
            sendDonation(_campaignId);
        }

    }

    function refundState(uint256 _campaignId) external view returns (bool) {
        return campaignList[_campaignId].campaign_refund_state;
    } // refund 상태 확인 

    function setStateToRefund(uint256 _campaignId) external onlyMinter { // 환불 모드로 변경, 해당 캠페인 정지 -> 접근 권한 제한 필요 onlyMinter로 contract 생성자만 접근 가능 
        campaignList[_campaignId].campaign_refund_state = true;
        campaignList[_campaignId].campaign_state = false;
    }

    // 환불
    function refund(uint256 _campaignId, address _userAddr) external {
        require(campaignList[_campaignId].campaign_refund_state == true, "this campaign is not refund state");
        require(campaignList[_campaignId].current_amount != 0, "all funds are returned");
        require(campaignList[_campaignId].campaign_fundingAmountList[_userAddr] != 0, "your funds are refurned");
        
        address msgSender = msg.sender;
        address payable _to = address(uint160(msgSender));

        uint256 refundAmount = campaignList[_campaignId].campaign_fundingAmountList[_userAddr];

        _to.call.value(refundAmount)("");  
        campaignList[_campaignId].campaign_fundingAmountList[_userAddr] = 0;
        campaignList[_campaignId].current_amount -= refundAmount;
    }

    
 
}
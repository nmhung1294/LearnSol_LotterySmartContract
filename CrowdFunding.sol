// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.5;
 
contract CrowdFunding {
    // Map lưu lại địa chỉ người ủng hộ và số tiền họ ủng hộ
    mapping(address => uint) public contributors;
    // Admin là người tạo ra hợp đồng
    address public admin;
    // Số người ủng hộ
    uint public noOfContributors;
    // Số tiền tối thiểu mỗi người ủng hộ
    uint public minimumContribution;
    // Thời gian kết thúc ủng hộ
    uint public deadline; 
    // Mục tiêu cần đạt được
    uint public goal;
    // Số tiền đã ủng hộ
    uint public raisedAmount;

    
    /*
    Struct lưu lại mỗi yêu cầu chi tiền, gồm có:
    + Mô tả: ví dụ chi để làm gì?
    + Người nhận: địa chỉ người nhận tiền
    + Số tiền cần chi
    + Trạng thái đã hoàn thành hay chưa
    + Số người đã vote, trên 50% số người vote thì mới được chi tiền
    + mapping lưu lại người đã vote
    */
    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters; 
        mapping(address => bool) voters;
    }
    
    // Mảng lưu lại các yêu cầu chi tiền
    // Mỗi yêu cầu sẽ có một số thứ tự
    mapping(uint => Request) public requests;
    uint public numRequests;

    //event
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);
    
    /*
    Constructor khởi tạo hợp đồng với mục tiêu và thời gian kết thúc ủng hộ
    admin: người triển khai hợp đồng
    */
    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        admin = msg.sender;
        minimumContribution = 100 wei;
    }
    
   // Modifier chỉ cho phép admin thực hiện
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this");
        _;
    }
    
    // Người khác có thể ủng hộ bằng cách gửi tiền vào hợp đồng
    function contribute() public payable {
        require(block.timestamp < deadline, "The Deadline has passed!");
        require(msg.value >= minimumContribution, "The Minimum Contribution not met!");

        if(contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        emit ContributeEvent(msg.sender, msg.value);
    }
    
    // Lấy số dư của hợp đồng
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    // Người đóng góp có thể yêu cầu hoàn lại tiền nếu không đạt mục tiêu
    function getRefund() public {
        require(block.timestamp > deadline, "Deadline has not passed.");
        require(raisedAmount < goal, "The goal was met");
        require(contributors[msg.sender] > 0);
        
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        contributors[msg.sender] = 0;  
        recipient.transfer(value);
    }
    
    // Admin tạo yêu cầu thông qua hàm này
    function createRequest(string calldata _description, address payable _recipient, uint _value) public onlyAdmin {
        //numRequests starts from zero
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
        
        emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    // Người đóng góp vote thông qua gọi hàm này
    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "You must be a contributor to vote!");
        
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "You have already voted!");
        
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }
    
    //Sau khi đã đủ số lượng người vote cho request, admin có thể chuyển tiền cho người nhận
    function makePayment(uint _requestNo) public onlyAdmin {
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "The request has been already completed!");
        
        require(thisRequest.noOfVoters > noOfContributors / 2, "The request needs more than 50% of the contributors.");
        
        // cập nhật trạng thái thành true và chuyển cho người nhận
        thisRequest.completed = true;
        thisRequest.recipient.transfer(thisRequest.value);
        // phát sự kiện chuyển tiền
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }  
}
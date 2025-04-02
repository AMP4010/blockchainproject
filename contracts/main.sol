// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "./utils.sol";

contract main {
    bytes32 private donorPass;
    bytes32 private recipientPass;
    bytes32 private matchedPass;
    mapping(uint8 => string[]) private minHLA;

    constructor (string memory _donorPass, string memory _recipientPass, string memory _matchedPass) {
        donorPass = keccak256(abi.encodePacked(_donorPass));
        recipientPass = keccak256(abi.encodePacked(_recipientPass));
        matchedPass = keccak256(abi.encodePacked(_matchedPass));
        minHLA[9] = ["blood stem cell", "bone marrow"];
        minHLA[7] = ["arm", "eye", "face", "hand", "leg", "penis", "scalp", "thymus"];
        minHLA[5] = ["abdominal wall", "adrenal gland", "bone", "esophagus", "larynx", "lymph node", "nail bed", "nerve", "ovary", "pancreas", "skin", "small intestine", "spleen", "stomach", "testicle", "trachea", "uterus"];
        minHLA[2] = ["blood vessel", "cartilage", "fat", "heart", "ligament", "lung", "meniscus", "tendon"];
        minHLA[0] = ["cornea", "heart valve", "liver"];
    }

    function passCheck(string memory _pass, bytes32 _PASS) private pure {
        require(keccak256(abi.encodePacked(_pass)) == _PASS);
    }

    modifier dlPassCheck(string memory _pass) {
        passCheck(_pass, donorPass);
        _;
    }

    modifier rlPassCheck(string memory _pass) {
        passCheck(_pass, recipientPass);
        _;
    }

    modifier mlPassCheck(string memory _pass) {
        passCheck(_pass, matchedPass);
        _;
    }

    event MatchFound(
        utils.persInfo info,
        string organ,
        uint8 mP,
        uint8 qty
    );

    uint8[] private posBT;
    utils.orgdet[] private donorList;
    utils.orgdet[] private recipientList;
    utils.matched_orgdet[] private matchedList;

    //                                     Donors --->
    //                                     A+ A- B+ B- AB+ AB-O+ O-Rh0 Hh+
    uint8[10][10] internal compatMatrix = [[1, 1, 0, 0, 0, 0, 1, 1, 0, 0],
                                           [0, 1, 0, 0, 0, 0, 0, 1, 0, 0],
                                           [0, 0, 1, 1, 0, 0, 1, 1, 0, 0],
                                           [0, 0, 0, 1, 0, 0, 0, 1, 0, 0],
                                           [1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
                                           [0, 1, 0, 1, 0, 1, 0, 1, 0, 0],
                                           [0, 0, 0, 0, 0, 0, 1, 1, 0, 0],
                                           [0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
                                           [0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
                                           [0, 0, 0, 0, 0, 0, 0, 0, 0, 1]];

    function regDonor(utils.persInfo memory _info, string memory _organ, uint8 _quantity, utils.HLA memory _report) external {

        delete posBT;
        utils.getPosBT(_info.bloodtype, compatMatrix, posBT, 0);
        bool matchFound = false;

        for (uint256 i = 0; i < recipientList.length; i++) {
            if (keccak256(bytes(recipientList[i].organ)) == keccak256(bytes(_organ))) {
                for (uint8 j = 0; j < posBT.length; j++) {
                    if (recipientList[i].info.bloodtype == posBT[j]) {
                        uint8 matchScore = 0;
                        matchScore = utils.getHLA(_report, recipientList[i].report, matchScore);
                        if (matchScore >= utils.getHlaCat(_organ, minHLA)) {
                            matchFound = true;
                            emit MatchFound(recipientList[i].info, recipientList[i].organ, recipientList[i].quantity, (matchScore*10));
                            int8 pendingqty = int8(_quantity) - int8(recipientList[i].quantity);
                            if (pendingqty > 0) {
                                utils.pushMatch(matchedList, _info, recipientList[i].info, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity, _report, recipientList[i].report);
                                utils.pushNew(donorList, _info, _organ, uint8(pendingqty), _report);
                                utils.pop(recipientList, i);
                                break;
                            } else if (pendingqty == 0) {
                                utils.pushMatch(matchedList, _info, recipientList[i].info, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity, _report, recipientList[i].report);
                                utils.pop(recipientList, i);
                                break;
                            } else {
                                utils.pushMatch(matchedList, _info, recipientList[i].info, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity, _report, recipientList[i].report);
                                recipientList[i].quantity = uint8(pendingqty * -1);
                                break;
                            }
                        }
                    }
                }
            }
        }

        if (!matchFound) {
            utils.pushNew(donorList, _info, _organ, _quantity, _report);
        }
    }

    function regRecipient(utils.persInfo memory _info, string memory _organ, uint8 _quantity, utils.HLA memory _report) external {

        delete posBT;
        utils.getPosBT(_info.bloodtype, compatMatrix, posBT, 1);
        bool matchFound = false;

        for (uint256 i = 0; i < donorList.length; i++) {
            if (keccak256(bytes(donorList[i].organ)) == keccak256(bytes(_organ))) {
                for (uint8 j = 0; j < posBT.length; j++) {
                    if (donorList[i].info.bloodtype == posBT[j]) {
                        uint8 matchScore = 0;
                        matchScore = utils.getHLA(_report, donorList[i].report, matchScore);
                        if (matchScore >= utils.getHlaCat(_organ, minHLA)) {
                            matchFound = true;
                            emit MatchFound(donorList[i].info, donorList[i].organ, donorList[i].quantity, matchScore*10);
                            int8 remainingqty = int8(_quantity) - int8(donorList[i].quantity);
                            if (remainingqty > 0 ) {
                        	    utils.pushMatch(matchedList, donorList[i].info, _info, _organ, donorList[i].quantity, _quantity, donorList[i].quantity, donorList[i].report, _report);
                                utils.pushNew(recipientList, _info, _organ, uint8(remainingqty), _report);
                                utils.pop(donorList, i);
                                break;
                            } else if (remainingqty == 0) {
                                utils.pushMatch(matchedList, donorList[i].info, _info, _organ, donorList[i].quantity, _quantity, donorList[i].quantity, donorList[i].report, _report);
                                utils.pop(donorList, i);
                                break;
                            } else {
                                utils.pushMatch(matchedList, donorList[i].info, _info, _organ, donorList[i].quantity, _quantity, donorList[i].quantity, donorList[i].report, _report);
                                donorList[i].quantity = uint8(remainingqty * -1);
                                break;
                            }
                        }
                    }
                }
            }
        }

        if (!matchFound) {
            utils.pushNew(recipientList, _info, _organ, _quantity, _report);
        }
    }

    function showDonors(string memory _pass) external view dlPassCheck(_pass) returns (utils.orgdet[] memory) {
        return donorList;
    }

    function showRecipient(string memory _pass) public view rlPassCheck(_pass) returns (utils.orgdet[] memory) {
        return recipientList;
    }

    function showMatches(string memory _pass) public view mlPassCheck(_pass) returns (utils.matched_orgdet[] memory) {
        return matchedList;
    }
}
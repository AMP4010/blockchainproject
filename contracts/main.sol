// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract main {
	bytes32 private donorPass;
	bytes32 private recipientPass;
	bytes32 private matchedPass;

	constructor (string memory _donorPass, string memory _recipientPass, string memory _matchedPass) {
		donorPass = keccak256(abi.encodePacked(_donorPass));
		donorPass = keccak256(abi.encodePacked(donorPass));
		recipientPass = keccak256(abi.encodePacked(_recipientPass));
		recipientPass = keccak256(abi.encodePacked(recipientPass));
		matchedPass = keccak256(abi.encodePacked(_matchedPass));
		matchedPass = keccak256(abi.encodePacked(matchedPass));
	}

	modifier dlPassCheck(string memory _pass) {
		require(keccak256(abi.encodePacked(keccak256(abi.encodePacked(_pass)))) == donorPass, "Incorrect password!");
		_;
	}

	modifier rlPassCheck(string memory _pass) {
		require(keccak256(abi.encodePacked(keccak256(abi.encodePacked(_pass)))) == recipientPass, "Incorrect password!");
		_;
	}

	modifier mlPassCheck(string memory _pass) {
		require(keccak256(abi.encodePacked(keccak256(abi.encodePacked(_pass)))) == matchedPass, "Incorrect password!");
		_;
	}

	struct orgdet {
		string owner;
		uint256 bloodtype;
		string organ;
		uint256 quantity;
	}

	struct matched_orgdet {
		string donor;
		string recipient;
		uint256 donorbloodtype;
		uint256 recipientbloodtype;
		string organ;
		uint256 donorquantity;
		uint256 recipientquantity;
		uint256 matchedquantity;
	}

	event DonMatchFound(
		string donorOwner,
		uint256 donorBloodType,
		string donorOrgan,
		uint256 donorQuantity
	);

	event RecMatchFound(
		string recipientOwner,
		uint256 recipientBloodType,
		string recipientOrgan,
		uint256 recipientQuantity
	);

	orgdet[] private donorList;
	orgdet[] private recipientList;
	matched_orgdet[] private matchedList;

	//                                      Donors --->
	//                                      A+ A- B+ B- AB+ AB-O+ O-Rh0 Hh+
	uint256[10][10] private compatMatrix = [[1, 1, 0, 0, 0, 0, 1, 1, 0, 0],
											[0, 1, 0, 0, 0, 0, 0, 1, 0, 0],
											[0, 0, 1, 1, 0, 0, 1, 1, 0, 0],
											[0, 0, 0, 1, 0, 0, 0, 1, 0, 0],
											[1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
											[0, 1, 0, 1, 0, 1, 0, 1, 0, 0],
											[0, 0, 0, 0, 0, 0, 1, 1, 0, 0],
											[0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
											[0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
											[0, 0, 0, 0, 0, 0, 0, 0, 0, 1]];

	uint256[] private posBT;

	function pop(orgdet[] storage _list, uint256 _i) private {
		orgdet memory temp = _list[_i];
		_list[_i] = _list[_list.length - 1];
		_list[_list.length - 1] = temp;
		_list.pop();
	}

	function pushMatch(string memory _donor, string memory _recipient, uint256 _dbt, uint256 _rbt, string memory _organ, uint256 _dqty, uint256 _rqty, uint256 _mqty) private {
		matched_orgdet memory match_det = matched_orgdet({
			donor: _donor,
			recipient: _recipient,
			donorbloodtype: _dbt,
			recipientbloodtype: _rbt,
			organ: _organ,
			donorquantity: _dqty,
			recipientquantity: _rqty,
			matchedquantity: _mqty
		});
		matchedList.push(match_det);
	}

	function pushNew(string memory _owner, uint256 _bloodtype, string memory _organ, uint256 _quantity, uint256 _type) private {
		orgdet memory newEntry = orgdet({
			owner: _owner,
			bloodtype: _bloodtype,
			organ: _organ,
			quantity: uint256(_quantity)
		});
		if (_type == 0) {
			donorList.push(newEntry);
		} else {
			recipientList.push(newEntry);
		}
	}

	function findMatchORaddDonor(string memory _owner, uint256 _bloodtype, string memory _organ, uint256 _quantity) public {

		if (_bloodtype == 8 || _bloodtype == 9) {
			posBT = [_bloodtype];
		} else {
			for (uint256 i = 0; i < 8; i++) {
				if (compatMatrix[i][_bloodtype] == 1) {
					posBT.push(i);
				}
			}
		}

		bool matchFound = false;

		for (uint256 i = 0; i < recipientList.length; i++) {
			if (keccak256(bytes(recipientList[i].organ)) == keccak256(bytes(_organ))) {
				for (uint256 j = 0; j <	posBT.length; j++) {
					if (recipientList[i].bloodtype == posBT[j]) {
						matchFound = true;
						emit RecMatchFound(recipientList[i].owner, recipientList[i].bloodtype, recipientList[i].organ, recipientList[i].quantity);
						int256 pendingqty = int256(_quantity) - int256(recipientList[i].quantity);
						if (pendingqty > 0) {
							pushMatch(_owner, recipientList[i].owner, _bloodtype, recipientList[i].bloodtype, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity);
							pushNew(_owner, _bloodtype, _organ, uint256(pendingqty), 0);
							pop(recipientList, i);
							break;
						} else if (pendingqty == 0) {
							pushMatch(_owner, recipientList[i].owner, _bloodtype, recipientList[i].bloodtype, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity);
							pop(recipientList, i);
							break;
						} else {
							pushMatch(_owner, recipientList[i].owner, _bloodtype, recipientList[i].bloodtype, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity);
							recipientList[i].quantity = uint256(pendingqty * -1);
							break;
						}
					}
				}
			}
		}

		if (!matchFound) {
			pushNew(_owner, _bloodtype, _organ, _quantity, 0);
		}
	}

	function findMatchORaddRecipient(string memory _owner, string memory _organ, uint256 _bloodtype, uint256 _quantity) public {

		if (_bloodtype == 8 || _bloodtype == 9) {
			posBT = [_bloodtype];
		} else {
			for (uint256 i = 0; i < 8; i++) {
				if (compatMatrix[_bloodtype][i] == 1) {
					posBT.push(i);
				}
			}
		}

		bool matchFound = false;

		for (uint256 i = 0; i < donorList.length; i++) {
			if (keccak256(bytes(donorList[i].organ)) == keccak256(bytes(_organ))) {
				for (uint256 j = 0; j <	posBT.length; j++) {
					if (donorList[i].bloodtype == posBT[j]) {
						matchFound = true;
						emit DonMatchFound(donorList[i].owner, donorList[i].bloodtype, donorList[i].organ, donorList[i].quantity);
						int256 remainingqty = int256(_quantity) - int256(donorList[i].quantity);
						if (remainingqty > 0 ) {
							pushMatch(donorList[i].owner, _owner, donorList[i].bloodtype, _bloodtype, _organ, donorList[i].quantity, _quantity, donorList[i].quantity);
							pushNew(_owner, _bloodtype, _organ, uint256(remainingqty), 1);
							pop(donorList, i);
							break;
						} else if (remainingqty == 0) {
							pushMatch(donorList[i].owner, _owner, donorList[i].bloodtype, _bloodtype, _organ, donorList[i].quantity, _quantity, donorList[i].quantity);
							pop(donorList, i);
							break;
						} else {
							pushMatch(donorList[i].owner, _owner, donorList[i].bloodtype, _bloodtype, _organ, donorList[i].quantity, _quantity, donorList[i].quantity);
							donorList[i].quantity = uint256(remainingqty * -1);
							break;
						}
					}
				}
			}
		}

		if (!matchFound) {
			pushNew(_owner, _bloodtype, _organ, _quantity, 1);
		}
	}

	function showDonors(string memory _pass) public view dlPassCheck(_pass) returns (orgdet[] memory) {
		return donorList;
	}

	function showRecipient(string memory _pass) public view rlPassCheck(_pass) returns (orgdet[] memory) {
		return recipientList;
	}

	function showMatches(string memory _pass) public view mlPassCheck(_pass) returns (matched_orgdet[] memory) {
		return matchedList;
	}
}

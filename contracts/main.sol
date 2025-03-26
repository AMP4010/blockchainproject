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

	uint256[] private posRecBT;
	uint256[] private posDonBT;

	function pop(orgdet[] storage _list, uint256 _i) private {
		orgdet memory temp = _list[_i];
		_list[_i] = _list[_list.length - 1];
		_list[_list.length - 1] = temp;
		_list.pop();
	}

	function findMatchORaddDonor(string memory _owner, uint256 _bloodtype, string memory _organ, uint256 _quantity) public {

		if (_bloodtype == 8 || _bloodtype == 9) {
			posRecBT = [_bloodtype];
		} else {
			for (uint256 i = 0; i < 8; i++) {
				if (compatMatrix[i][_bloodtype] == 1) {
					posRecBT.push(i);
				}
			}
		}

		bool matchFound = false;

		for (uint256 i = 0; i < recipientList.length; i++) {
			if (keccak256(bytes(recipientList[i].organ)) == keccak256(bytes(_organ))) {
				for (uint256 j = 0; j < posRecBT.length; j++) {
					if (recipientList[i].bloodtype == posRecBT[j]) {
						matchFound = true;
						emit RecMatchFound(recipientList[i].owner, recipientList[i].bloodtype, recipientList[i].organ, recipientList[i].quantity);
						int256 pendingqty = int256(_quantity) - int256(recipientList[i].quantity);
						if (pendingqty > 0) {
							matched_orgdet memory match_det = matched_orgdet({
								donor: _owner,
								recipient: recipientList[i].owner,
								donorbloodtype: _bloodtype,
								recipientbloodtype: recipientList[i].bloodtype,
								organ: _organ,
								donorquantity: _quantity,
								recipientquantity: recipientList[i].quantity,
								matchedquantity: recipientList[i].quantity
							});
							matchedList.push(match_det);
							orgdet memory newDonor = orgdet({
								owner: _owner,
								bloodtype: _bloodtype,
								organ: _organ,
								quantity: uint256(pendingqty)
							});
							donorList.push(newDonor);
							pop(recipientList, i);
							break;
						} else if (pendingqty == 0) {
							matched_orgdet memory match_det = matched_orgdet({
								donor: _owner,
								recipient: recipientList[i].owner,
								donorbloodtype: _bloodtype,
								recipientbloodtype: recipientList[i].bloodtype,
								organ: _organ,
								donorquantity: _quantity,
								recipientquantity: recipientList[i].quantity,
								matchedquantity: recipientList[i].quantity
							});
							matchedList.push(match_det);
							pop(recipientList, i);
							break;
						} else {
							matched_orgdet memory match_det = matched_orgdet({
								donor: _owner,
								recipient: recipientList[i].owner,
								donorbloodtype: _bloodtype,
								recipientbloodtype: recipientList[i].bloodtype,
								organ: _organ,
								donorquantity: _quantity,
								recipientquantity: recipientList[i].quantity,
								matchedquantity: recipientList[i].quantity
							});
							matchedList.push(match_det);
							recipientList[i].quantity = uint256(pendingqty * -1);
							break;
						}
					}
				}
			}
		}

		if (!matchFound) {
			orgdet memory newDonor = orgdet({
				owner: _owner,
				bloodtype: _bloodtype,
				organ: _organ,
				quantity: _quantity
			});
			donorList.push(newDonor);
		}
	}

	function findMatchORaddRecipient(string memory _owner, string memory _organ, uint256 _bloodtype, uint256 _quantity) public {

		if (_bloodtype == 8 || _bloodtype == 9) {
			posDonBT = [_bloodtype];
		} else {
			for (uint256 i = 0; i < 8; i++) {
				if (compatMatrix[_bloodtype][i] == 1) {
					posDonBT.push(i);
				}
			}
		}

		bool matchFound = false;

		for (uint256 i = 0; i < donorList.length; i++) {
			if (keccak256(bytes(donorList[i].organ)) == keccak256(bytes(_organ))) {
				for (uint256 j = 0; j < posDonBT.length; j++) {
					if (donorList[i].bloodtype == posDonBT[j]) {
						matchFound = true;
						emit DonMatchFound(donorList[i].owner, donorList[i].bloodtype, donorList[i].organ, donorList[i].quantity);
						int256 remainingqty = int256(_quantity) - int256(donorList[i].quantity);
						if (remainingqty > 0 ) {
							matched_orgdet memory match_det = matched_orgdet({
								donor: donorList[i].owner,
								recipient: _owner,
								donorbloodtype: donorList[i].bloodtype,
								recipientbloodtype: _bloodtype,
								organ: _organ,
								donorquantity: donorList[i].quantity,
								recipientquantity: _quantity,
								matchedquantity: donorList[i].quantity
							});
							matchedList.push(match_det);
							orgdet memory newRecipient = orgdet({
								owner: _owner,
								bloodtype: _bloodtype,
								organ: _organ,
								quantity: uint256(remainingqty)
							});
							recipientList.push(newRecipient);
							pop(donorList, i);
							break;
						} else if (remainingqty == 0) {
							matched_orgdet memory match_det = matched_orgdet({
								donor: donorList[i].owner,
								recipient: _owner,
								donorbloodtype: donorList[i].bloodtype,
								recipientbloodtype: _bloodtype,
								organ: _organ,
								donorquantity: donorList[i].quantity,
								recipientquantity: _quantity,
								matchedquantity: donorList[i].quantity
							});
							matchedList.push(match_det);
							pop(donorList, i);
							break;
						} else {
							matched_orgdet memory match_det = matched_orgdet({
								donor: donorList[i].owner,
								recipient: _owner,
								donorbloodtype: donorList[i].bloodtype,
								recipientbloodtype: _bloodtype,
								organ: _organ,
								donorquantity: donorList[i].quantity,
								recipientquantity: _quantity,
								matchedquantity: donorList[i].quantity
							});
							matchedList.push(match_det);
							donorList[i].quantity = uint256(remainingqty * -1);
							break;
						}
					}
				}
			}
		}

		if (!matchFound) {
			orgdet memory newRecipient = orgdet({
				owner: _owner,
				bloodtype: _bloodtype,
				organ: _organ,
				quantity: _quantity
			});
			recipientList.push(newRecipient);
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

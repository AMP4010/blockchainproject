// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract main {
	bytes32 private donorPass;
	bytes32 private recipientPass;
	bytes32 private matchedPass;
	mapping(uint256 => string[]) private minHLA;

	constructor (string memory _donorPass, string memory _recipientPass, string memory _matchedPass) {
		donorPass = keccak256(abi.encodePacked(_donorPass));
		donorPass = keccak256(abi.encodePacked(donorPass));
		recipientPass = keccak256(abi.encodePacked(_recipientPass));
		recipientPass = keccak256(abi.encodePacked(recipientPass));
		matchedPass = keccak256(abi.encodePacked(_matchedPass));
		matchedPass = keccak256(abi.encodePacked(matchedPass));
		minHLA[9] = ["blood stem cell", "bone marrow"];
        minHLA[7] = ["arm", "eye", "face", "hand", "leg", "penis", "scalp", "thymus"];
        minHLA[5] = ["abdominal wall", "adrenal gland", "bone", "esophagus", "larynx", "lymph node", "nail bed", "nerve", "ovary", "pancreas", "skin", "small intestine", "spleen", "stomach", "testicle", "trachea", "uterus"];
        minHLA[2] = ["blood vessel", "cartilage", "fat", "heart", "ligament", "lung", "meniscus", "tendon"];
        minHLA[0] = ["cornea", "heart valve", "liver"];
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
	
	struct HLA {
		string allele1;
		string allele2;
	}

	struct orgdet {
		string owner;
		uint256 age;
		uint256 bloodtype;
		string organ;
		uint256 quantity;
		HLA hla_a;
		HLA hla_b;
		HLA hla_c;
		HLA hla_drb1;
		HLA hla_dqb1;
		string hospital;
	}

	struct matched_orgdet {
		string donor;
		uint256 donorage;
		string recipient;
		uint256 recipientage;
		uint256 donorbloodtype;
		uint256 recipientbloodtype;
		string organ;
		uint256 donorquantity;
		uint256 recipientquantity;
		uint256 matchedquantity;
		string donorhosp;
		string recipienthosp;
	}

	event DonMatchFound(
		string donorOwner,
		uint256 donorAge,
		uint256 donorBloodType,
		string donorOrgan,
		uint256 donorQuantity,
		uint256 matchPC,
		string donorHospital
	);

	event RecMatchFound(
		string recipientOwner,
		uint256 recipientAge,
		uint256 recipientBloodType,
		string recipientOrgan,
		uint256 recipientQuantity,
		uint256 matchPC,
		string recipientHospital
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

	function lowerString(string memory _text) private returns (string memory) {
		bytes memory btext = bytes(_text);
		for (uint256 i = 0; i < btext.length; i++) {
			if (btext[i] >= 0x41 && btext[i] <= 0x5A) {
                btext[i] = bytes1(uint8(btext[i]) + 32);
            }
		}
		return string(btext);
	}

	function compAll(string memory o1_all, string memory o2_all) private returns (uint256) {
		uint256 a1 = (uint8(bytes(o1_all)[0]) - 48) * 10 + (uint8(bytes(o1_all)[1]) - 48);
        uint256 a2 = (uint8(bytes(o2_all)[0]) - 48) * 10 + (uint8(bytes(o2_all)[1]) - 48);
        uint256 b1 = (uint8(bytes(o1_all)[3]) - 48) * 10 + (uint8(bytes(o1_all)[4]) - 48);
        uint256 b2 = (uint8(bytes(o2_all)[3]) - 48) * 10 + (uint8(bytes(o2_all)[4]) - 48);
		uint256 c1 = (uint8(bytes(o1_all)[6]) - 48) * 10 + (uint8(bytes(o1_all)[7]) - 48);
        uint256 c2 = (uint8(bytes(o2_all)[6]) - 48) * 10 + (uint8(bytes(o2_all)[7]) - 48);
		if (a1 == a2 && b1 == b2 && c1 == c2) {
			return 1;
		} else {
			return 0;
		}
	}

	function getMinHLA(uint256 min, string memory a, string memory b, string memory c, string memory d, string memory e, string memory f, string memory g, string memory h, string memory i, string memory j, string memory k, string memory l, string memory m, string memory n, string memory o, string memory p, string memory q, string memory r, string memory s, string memory t) private returns (uint256) {
		min += compAll(a, b) + compAll(c, d);
		min += compAll(e, f) + compAll(g, h);
		min += compAll(i, j) + compAll(k, l);
		min += compAll(m, n) + compAll(o, p);
		min += compAll(q, r) + compAll(s, t);
		return min;
	}

	function pop(orgdet[] storage _list, uint256 _i) private {
		orgdet memory temp = _list[_i];
		_list[_i] = _list[_list.length - 1];
		_list[_list.length - 1] = temp;
		_list.pop();
	}

	function pushMatch(string memory _donor, uint256 _dage, string memory _recipient, uint256 _rage, uint256 _dbt, uint256 _rbt, string memory _organ, uint256 _dqty, uint256 _rqty, uint256 _mqty, string memory _dhosp, string memory _rhosp) private {
		matched_orgdet memory match_det = matched_orgdet({
			donor: _donor,
			donorage: _dage,
			recipient: _recipient,
			recipientage: _rage,
			donorbloodtype: _dbt,
			recipientbloodtype: _rbt,
			organ: _organ,
			donorquantity: _dqty,
			recipientquantity: _rqty,
			matchedquantity: _mqty,
			donorhosp: _dhosp,
			recipienthosp: _rhosp
		});
		matchedList.push(match_det);
	}

	function pushNew(string memory _owner, uint256 _age, uint256 _bloodtype, string memory _organ, uint256 _quantity, HLA memory _hla_a, HLA memory _hla_b, HLA memory _hla_c, HLA memory _hla_drb1, HLA memory _hla_dqb1, string memory _hospital, uint256 _type) private {
		orgdet memory newEntry = orgdet({
			owner: _owner,
			age: _age,
			bloodtype: _bloodtype,
			organ: _organ,
			quantity: uint256(_quantity),
			hla_a: _hla_a,
			hla_b: _hla_b,
			hla_c: _hla_c,
			hla_drb1: _hla_drb1,
			hla_dqb1: _hla_dqb1,
			hospital: _hospital
		});
		if (_type == 0) {
			donorList.push(newEntry);
		} else {
			recipientList.push(newEntry);
		}
	}

	function regDonor(string memory _owner, uint256 _age, uint256 _bloodtype, string memory _organ, uint256 _quantity, HLA memory _hla_a, HLA memory _hla_b, HLA memory _hla_c, HLA memory _hla_drb1, HLA memory _hla_dqb1, string memory _hospital) public {

		if (_bloodtype == 8 || _bloodtype == 9) {
			posBT = [_bloodtype];
		} else {
			for (uint256 i = 0; i < 8; i++) {
				if (compatMatrix[i][_bloodtype] == 1) {
					posBT.push(i);
				}
			}
		}

		_organ = lowerString(_organ);
		uint256 minHla;
		uint8[5] memory scores = [9, 7, 5, 2, 0];
        for (uint256 i = 0; i < scores.length; i++) {
            string[] memory organs = minHLA[scores[i]];
            for (uint256 j = 0; j < organs.length; j++) {
                if (keccak256(bytes(organs[j])) == keccak256(bytes(_organ))) {
                    minHla = scores[i];
                }
            }
		}

		bool matchFound = false;

		for (uint256 i = 0; i < recipientList.length; i++) {
			if (keccak256(bytes(recipientList[i].organ)) == keccak256(bytes(_organ))) {
				for (uint256 j = 0; j <	posBT.length; j++) {
					if (recipientList[i].bloodtype == posBT[j]) {
						uint256 m = 0;
						m = getMinHLA(m, _hla_a.allele1, recipientList[i].hla_a.allele1, _hla_a.allele2, recipientList[i].hla_a.allele2, _hla_b.allele1, recipientList[i].hla_b.allele1, _hla_b.allele2, recipientList[i].hla_b.allele2, _hla_c.allele1, recipientList[i].hla_c.allele1, _hla_c.allele2, recipientList[i].hla_c.allele2, _hla_drb1.allele1, recipientList[i].hla_drb1.allele1, _hla_drb1.allele2, recipientList[i].hla_drb1.allele2, _hla_dqb1.allele1, recipientList[i].hla_dqb1.allele1, _hla_dqb1.allele2, recipientList[i].hla_dqb1.allele2);
						if (m >= minHla) {
							matchFound = true;
							uint256 matchPC = (minHla/10) * 100;
							emit RecMatchFound(recipientList[i].owner, recipientList[i].age, recipientList[i].bloodtype, recipientList[i].organ, recipientList[i].quantity, matchPC, recipientList[i].hospital);
							int256 pendingqty = int256(_quantity) - int256(recipientList[i].quantity);
							if (pendingqty > 0) {
								pushMatch(_owner, _age, recipientList[i].owner, recipientList[i].age, _bloodtype, recipientList[i].bloodtype, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity, _hospital, recipientList[i].hospital);
								pushNew(_owner, _age, _bloodtype, _organ, uint256(pendingqty), _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital, 0);
								pop(recipientList, i);
								break;
							} else if (pendingqty == 0) {
								pushMatch(_owner, _age, recipientList[i].owner, recipientList[i].age, _bloodtype, recipientList[i].bloodtype, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity, _hospital, recipientList[i].hospital);
								pop(recipientList, i);
								break;
							} else {
								pushMatch(_owner, _age, recipientList[i].owner, recipientList[i].age, _bloodtype, recipientList[i].bloodtype, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity, _hospital, recipientList[i].hospital);
								recipientList[i].quantity = uint256(pendingqty * -1);
								break;
							}
						}
					}
				}
			}
		}

		if (!matchFound) {
			pushNew(_owner, _age, _bloodtype, _organ, _quantity, _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital, 0);
		}
	}

	function regRecipient(string memory _owner, uint256 _age, string memory _organ, uint256 _bloodtype, uint256 _quantity, HLA memory _hla_a, HLA memory _hla_b, HLA memory _hla_c, HLA memory _hla_drb1, HLA memory _hla_dqb1, string memory _hospital) public {

		if (_bloodtype == 8 || _bloodtype == 9) {
			posBT = [_bloodtype];
		} else {
			for (uint256 i = 0; i < 8; i++) {
				if (compatMatrix[_bloodtype][i] == 1) {
					posBT.push(i);
				}
			}
		}

		_organ = lowerString(_organ);
		uint256 minHla;
		uint8[5] memory scores = [9, 7, 5, 2, 0];
        for (uint256 i = 0; i < scores.length; i++) {
            string[] memory organs = minHLA[scores[i]];
            for (uint256 j = 0; j < organs.length; j++) {
                if (keccak256(bytes(organs[j])) == keccak256(bytes(_organ))) {
                    minHla = scores[i];
                }
            }
		}

		bool matchFound = false;

		for (uint256 i = 0; i < donorList.length; i++) {
			if (keccak256(bytes(donorList[i].organ)) == keccak256(bytes(_organ))) {
				for (uint256 j = 0; j <	posBT.length; j++) {
					if (donorList[i].bloodtype == posBT[j]) {
						matchFound = true;
						uint256 matchPC = (minHla/10) * 100;
						emit DonMatchFound(donorList[i].owner, donorList[i].age, donorList[i].bloodtype, donorList[i].organ, donorList[i].quantity, matchPC, donorList[i].hospital);
						int256 remainingqty = int256(_quantity) - int256(donorList[i].quantity);
						if (remainingqty > 0 ) {
							pushMatch(donorList[i].owner, donorList[i].age, _owner, _age, donorList[i].bloodtype, _bloodtype, _organ, donorList[i].quantity, _quantity, donorList[i].quantity, donorList[i].hospital, _hospital);
							pushNew(_owner, _age, _bloodtype, _organ, uint256(remainingqty), _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital, 1);
							pop(donorList, i);
							break;
						} else if (remainingqty == 0) {
							pushMatch(donorList[i].owner, donorList[i].age, _owner, _age, donorList[i].bloodtype, _bloodtype, _organ, donorList[i].quantity, _quantity, donorList[i].quantity, donorList[i].hospital, _hospital);
							pop(donorList, i);
							break;
						} else {
							pushMatch(donorList[i].owner, donorList[i].age, _owner, _age, donorList[i].bloodtype, _bloodtype, _organ, donorList[i].quantity, _quantity, donorList[i].quantity, donorList[i].hospital, _hospital);
							donorList[i].quantity = uint256(remainingqty * -1);
							break;
						}
					}
				}
			}
		}

		if (!matchFound) {
			pushNew(_owner, _age, _bloodtype, _organ, _quantity, _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital, 1);
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

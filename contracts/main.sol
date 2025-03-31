// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./functions.sol";

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
		HLA don_hla_a;
		HLA don_hla_b;
		HLA don_hla_c;
		HLA don_hla_drb1;
		HLA don_hla_dqb1;
		HLA rec_hla_a;
		HLA rec_hla_b;
		HLA rec_hla_c;
		HLA rec_hla_drb1;
		HLA rec_hla_dqb1;
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
	uint8[5] private minScores = [9, 7, 5, 2, 0];

	function regDonor(string memory _owner, uint256 _age, uint256 _bloodtype, string memory _organ, uint256 _quantity, HLA memory _hla_a, HLA memory _hla_b, HLA memory _hla_c, HLA memory _hla_drb1, HLA memory _hla_dqb1, string memory _hospital) public {
		
		// posBT = functions.getPosBT(compatMatrix, _bloodtype);
		if (_bloodtype == 8 || _bloodtype == 9) {
			posBT = [_bloodtype];
		} else {
			for (uint256 i = 0; i < 8; i++) {
				if (compatMatrix[i][_bloodtype] == 1) {
					posBT.push(i);
				}
			}
		}

		_organ = functions.lowerString(_organ);
		uint256 minReqdHla = functions.getHlaCat(_organ, minHLA);
		bool matchFound = false;

		for (uint256 i = 0; i < recipientList.length; i++) {
			if (keccak256(bytes(recipientList[i].organ)) == keccak256(bytes(_organ))) {
				for (uint256 j = 0; j <	posBT.length; j++) {
					if (recipientList[i].bloodtype == posBT[j]) {
						uint256 matchScore = 0;
						matchScore = functions.getHLA(_hla_a.allele1, recipientList[i].hla_a.allele1, _hla_a.allele2, recipientList[i].hla_a.allele2, 
											 		  _hla_b.allele1, recipientList[i].hla_b.allele1, _hla_b.allele2, recipientList[i].hla_b.allele2, 
											 		  _hla_c.allele1, recipientList[i].hla_c.allele1, _hla_c.allele2, recipientList[i].hla_c.allele2, 
											          _hla_drb1.allele1, recipientList[i].hla_drb1.allele1, _hla_drb1.allele2, recipientList[i].hla_drb1.allele2, 
													  _hla_dqb1.allele1, recipientList[i].hla_dqb1.allele1, _hla_dqb1.allele2, recipientList[i].hla_dqb1.allele2, matchScore);
						if (matchScore >= minReqdHla) {
							matchFound = true;
							uint256 matchPC = (minReqdHla/10) * 100;
							emit RecMatchFound(recipientList[i].owner, recipientList[i].age, recipientList[i].bloodtype, recipientList[i].organ, recipientList[i].quantity, matchPC, recipientList[i].hospital);
							int256 pendingqty = int256(_quantity) - int256(recipientList[i].quantity);
							if (pendingqty > 0) {
								functions.pushMatch(matchedList, _owner, _age, recipientList[i].owner, recipientList[i].age, _bloodtype, recipientList[i].bloodtype, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity, _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, recipientList[i].hla_a, recipientList[i].hla_b, recipientList[i].hla_c, recipientList[i].hla_drb1, recipientList[i].hla_dqb1, _hospital, recipientList[i].hospital);
								functions.pushNew(donorList, _owner, _age, _bloodtype, _organ, uint256(pendingqty), _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital);
								functions.pop(recipientList, i);
								break;
							} else if (pendingqty == 0) {
								functions.pushMatch(_owner, _age, recipientList[i].owner, recipientList[i].age, _bloodtype, recipientList[i].bloodtype, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity, _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital, recipientList[i].hospital);
								functions.pop(recipientList, i);
								break;
							} else {
								functions.pushMatch(_owner, _age, recipientList[i].owner, recipientList[i].age, _bloodtype, recipientList[i].bloodtype, _organ, _quantity, recipientList[i].quantity, recipientList[i].quantity, _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital, recipientList[i].hospital);
								recipientList[i].quantity = uint256(pendingqty * -1);
								break;
							}
						}
					}
				}
			}
		}

		if (!matchFound) {
			functions.pushNew(_owner, _age, _bloodtype, _organ, _quantity, _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital, 0);
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

		_organ = functions.lowerString(_organ);
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
							functions.pushMatch(donorList[i].owner, donorList[i].age, _owner, _age, donorList[i].bloodtype, _bloodtype, _organ, donorList[i].quantity, _quantity, donorList[i].quantity, donorList[i].hospital, _hospital);
							functions.pushNew(_owner, _age, _bloodtype, _organ, uint256(remainingqty), _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital, 1);
							functions.pop(donorList, i);
							break;
						} else if (remainingqty == 0) {
							functions.pushMatch(donorList[i].owner, donorList[i].age, _owner, _age, donorList[i].bloodtype, _bloodtype, _organ, donorList[i].quantity, _quantity, donorList[i].quantity, donorList[i].hospital, _hospital);
							functions.pop(donorList, i);
							break;
						} else {
							functions.pushMatch(donorList[i].owner, donorList[i].age, _owner, _age, donorList[i].bloodtype, _bloodtype, _organ, donorList[i].quantity, _quantity, donorList[i].quantity, donorList[i].hospital, _hospital);
							donorList[i].quantity = uint256(remainingqty * -1);
							break;
						}
					}
				}
			}
		}

		if (!matchFound) {
			functions.pushNew(_owner, _age, _bloodtype, _organ, _quantity, _hla_a, _hla_b, _hla_c, _hla_drb1, _hla_dqb1, _hospital, 1);
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

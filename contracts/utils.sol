// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library utils {
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

	function getPosBT(uint256 _bloodtype, uint256[10][10] storage _compatMatrix, uint256[] storage _posBT, uint256 _mode) internal {
		if (_bloodtype == 8 || _bloodtype == 9) {
			_posBT.push(_bloodtype);
			return;
		}
		if (_mode == 0) {
			for (uint256 i = 0; i < 8; i++) {
				if (_compatMatrix[i][_bloodtype] == 1) {
					_posBT.push(i);
				}
			}
		} else {
			for (uint256 i = 0; i < 8; i++) {
				if (_compatMatrix[_bloodtype][i] == 1) {
					_posBT.push(i);
				}
			}
		}
	}

    function lowerString(string memory _text) internal pure returns (string memory) {
		bytes memory btext = bytes(_text);
		for (uint256 i = 0; i < btext.length; i++) {
			if (btext[i] >= 0x41 && btext[i] <= 0x5A) {
                btext[i] = bytes1(uint8(btext[i]) + 32);
            }
		}
		return string(btext);
	}

    function compAll(string memory o1_all, string memory o2_all) internal pure returns (uint256) {
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

    function getHlaCat(string memory _organ, mapping(uint256 => string[]) storage minHLA) internal view returns (uint256) {
        uint8[5] memory minScores = [9, 7, 5, 2, 0];
        uint256 cat;
        for (uint256 i = 0; i < minScores.length; i++) {
            string[] memory organs = minHLA[minScores[i]];
            for (uint256 j = 0; j < organs.length; j++) {
                if (keccak256(bytes(organs[j])) == keccak256(bytes(_organ))) {
                    cat = minScores[i];
                }
            }
		}
        return cat;
    }

	function getHLA(string memory a, string memory b, string memory c, string memory d,
                    string memory e, string memory f, string memory g, string memory h, 
                    string memory i, string memory j, string memory k, string memory l, 
                    string memory m, string memory n, string memory o, string memory p, 
                    string memory q, string memory r, string memory s, string memory t, 
                    uint256 min) internal pure returns (uint256) {
		min += compAll(a, b) + compAll(c, d);
		min += compAll(e, f) + compAll(g, h);
		min += compAll(i, j) + compAll(k, l);
		min += compAll(m, n) + compAll(o, p);
		min += compAll(q, r) + compAll(s, t);
		return min;
	}

	function pop(orgdet[] storage _list, uint256 _i) internal {
		orgdet memory temp = _list[_i];
		_list[_i] = _list[_list.length - 1];
		_list[_list.length - 1] = temp;
		_list.pop();
	}

	function pushMatch(matched_orgdet[] storage _matchedList, string memory _donor, uint256 _dage, string memory _recipient, uint256 _rage, uint256 _dbt, uint256 _rbt, string memory _organ, uint256 _dqty, uint256 _rqty, uint256 _mqty, HLA memory _d_hla_a, HLA memory _d_hla_b, HLA memory _d_hla_c, HLA memory _d_hla_drb1, HLA memory _d_hla_dqb1, HLA memory _r_hla_a, HLA memory _r_hla_b, HLA memory _r_hla_c, HLA memory _r_hla_drb1, HLA memory _r_hla_dqb1, string memory _dhosp, string memory _rhosp) internal {
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
            don_hla_a: _d_hla_a,
			don_hla_b: _d_hla_b,
			don_hla_c: _d_hla_c,
			don_hla_drb1: _d_hla_drb1,
			don_hla_dqb1: _d_hla_dqb1,
			rec_hla_a: _r_hla_a,
			rec_hla_b: _r_hla_b,
			rec_hla_c: _r_hla_c,
			rec_hla_drb1: _r_hla_drb1,
			rec_hla_dqb1: _r_hla_dqb1,
			donorhosp: _dhosp,
			recipienthosp: _rhosp
		});
		_matchedList.push(match_det);
	}

	function pushNew(orgdet[] storage _list, string memory _owner, uint256 _age, uint256 _bloodtype, string memory _organ, uint256 _quantity, HLA memory _hla_a, HLA memory _hla_b, HLA memory _hla_c, HLA memory _hla_drb1, HLA memory _hla_dqb1, string memory _hospital) internal {
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
        _list.push(newEntry);
	}
}
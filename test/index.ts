import { expect } from "chai";
import { ethers } from "hardhat";

const { getSelectors } = require("./Utils");

const MethodUpdateAction = { Add: 0, Replace: 1, Remove: 2 }

describe("ModuleRepository", function () {
  it("Should be able to add and remove methods", async function () {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]
  
    // deploy DiamondCutFacet
    const MethodUpdateModule = await ethers.getContractFactory('MethodUpdateModule')
    const methodUpdateModule = await MethodUpdateModule.deploy()
    await methodUpdateModule.deployed()
    console.log('MethodUpdateModule deployed:', methodUpdateModule.address);

    const App = await ethers.getContractFactory('App');
    const app = await App.deploy(contractOwner.address, methodUpdateModule.address)
    await app.deployed()
    console.log('App deployed:', app.address);

    const TestModule = await ethers.getContractFactory('TestModule')
    const testModule = await TestModule.deploy()
    await testModule.deployed()
    const selectors = getSelectors(testModule);

    // attach the method update module to the App address
    const methodUpdateModule_ = await ethers.getContractAt('MethodUpdateModule', app.address);
    const tx = await methodUpdateModule_.methodUpdate(
      [{
        methodAddress: testModule.address,
        action: MethodUpdateAction.Add,
        functionSelectors: selectors
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    const receipt = await tx.wait();

    // Attach the TestModule to the app address
    const testModule_ = await ethers.getContractAt('TestModule', app.address)
    await testModule_.testFunc1()
  });
});

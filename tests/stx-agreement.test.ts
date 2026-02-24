import { describe, it, expect, beforeEach } from 'vitest';
import { Clarinet, Tx, Chain, Account } from '@stacks/transactions';
import { callReadOnlyFn, broadcastTransaction, makeContractCall } from '@stacks/transactions';

describe('STX SLA Contract', () => {
  let deployer: Account;
  let serviceProvider: Account;
  let client: Account;
  let chain: Chain;

  beforeEach(() => {
    deployer = { address: 'SP123', secretKey: 'key1' } as Account;
    serviceProvider = { address: 'SP456', secretKey: 'key2' } as Account;
    client = { address: 'SP789', secretKey: 'key3' } as Account;
    chain = {} as Chain; // mock chain for simplicity
  });

  it('marks milestone as complete and updates agreement status when all milestones are done', async () => {
    const agreementId = 1;

    // mock initial agreement with all incomplete milestones
    await makeContractCall({
      senderKey: serviceProvider.secretKey,
      contractAddress: deployer.address,
      contractName: 'stx-sla',
      functionName: 'mark-milestone-complete',
      functionArgs: [
        Tx.uintCV(agreementId),
        Tx.uintCV(0),
      ],
      network: {} as any,
    });

    const details = await callReadOnlyFn({
      contractAddress: deployer.address,
      contractName: 'stx-sla',
      functionName: 'get-agreement-details',
      functionArgs: [Tx.uintCV(agreementId)],
      network: {} as any,
      senderAddress: serviceProvider.address,
    });

    expect(details).toBeDefined();
    const milestones = details.value.service_milestones;
    expect(milestones[0].milestone_completed).toBe(true);
  });

  it('allows authorized participants to initiate dispute', async () => {
    const agreementId = 1;
    const disputeReason = 'Work not delivered as promised';

    const result = await makeContractCall({
      senderKey: client.secretKey,
      contractAddress: deployer.address,
      contractName: 'stx-sla',
      functionName: 'initiate-dispute',
      functionArgs: [
        Tx.uintCV(agreementId),
        Tx.stringUtf8CV(disputeReason),
      ],
      network: {} as any,
    });

    expect(result).toBeTruthy();

    const disputeDetails = await callReadOnlyFn({
      contractAddress: deployer.address,
      contractName: 'stx-sla',
      functionName: 'get-dispute-details',
      functionArgs: [Tx.uintCV(agreementId)],
      network: {} as any,
      senderAddress: client.address,
    });

    expect(disputeDetails.value.dispute_reason).toBe(disputeReason);
    expect(disputeDetails.value.dispute_initiator).toBe(client.address);
  });

  it('prevents unauthorized users from marking milestone complete', async () => {
    const agreementId = 1;

    try {
      await makeContractCall({
        senderKey: client.secretKey,
        contractAddress: deployer.address,
        contractName: 'stx-sla',
        functionName: 'mark-milestone-complete',
        functionArgs: [
          Tx.uintCV(agreementId),
          Tx.uintCV(0),
        ],
        network: {} as any,
      });
      throw new Error('Unauthorized call did not fail');
    } catch (err: any) {
      expect(err).toBeDefined();
      expect(err.message).toMatch(/ERROR_UNAUTHORIZED_ACCESS/);
    }
  });
});

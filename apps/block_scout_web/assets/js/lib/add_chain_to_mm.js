import 'bootstrap'
import { commonPath } from './path_helper'

export async function addChainToMM ({ btn }) {
  try {
    // @ts-ignore
    const chainIDFromWallet = await window.ethereum.request({ method: 'eth_chainId' })
    const chainIDFromInstance = getChainIdHex()

    const coinNameObj = document.getElementById('js-coin-name')
    // @ts-ignore
    const coinName = coinNameObj && coinNameObj.value
    const coinSymbolObj = document.getElementById('js-coin-symbol')
    // @ts-ignore
    const coinSymbolRaw = (coinSymbolObj && coinSymbolObj.value) || coinName || ''
    const coinSymbol = coinSymbolRaw.slice(0, 6)
    const subNetworkObj = document.getElementById('js-subnetwork')
    // @ts-ignore
    const subNetwork = subNetworkObj && subNetworkObj.value
    const jsonRPCObj = document.getElementById('js-json-rpc')
    // @ts-ignore
    const jsonRPC = jsonRPCObj && jsonRPCObj.value

    const blockscoutURL = location.protocol + '//' + location.host + commonPath
    if (chainIDFromWallet !== chainIDFromInstance) {
      // @ts-ignore
      await window.ethereum.request({
        method: 'wallet_addEthereumChain',
        params: [{
          chainId: chainIDFromInstance,
          chainName: subNetwork,
          nativeCurrency: {
            name: coinName,
            symbol: coinSymbol,
            decimals: 18
          },
          rpcUrls: [jsonRPC],
          blockExplorerUrls: [blockscoutURL]
        }]
      })
    } else {
      btn.tooltip('dispose')
      btn.tooltip({
        title: `You're already connected to ${subNetwork}`,
        trigger: 'click',
        placement: 'bottom'
      }).tooltip('show')

      setTimeout(() => {
        btn.tooltip('dispose')
      }, 3000)
    }
  } catch (error) {
    console.error(error)
  }
}

function getChainIdHex () {
  const chainIDObj = document.getElementById('js-chain-id')
  // @ts-ignore
  const chainIDFromDOM = chainIDObj && chainIDObj.value
  const chainIDFromInstance = parseInt(chainIDFromDOM)
  return chainIDFromInstance && `0x${chainIDFromInstance.toString(16)}`
}
